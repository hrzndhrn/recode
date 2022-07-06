defmodule Recode.Task.AliasOrder do
  @moduledoc """
  Alphabetically sorted lists are easier to read.

      # preferred

      alias Alpha
      alias Bravo
      alias Delta.{Echo, Foxtrot}

      # not preferred

      alias Delta.{Foxtrot, Echo}
      alias Alpha
      alias Bravo
  """

  use Recode.Task, correct: true, check: true

  alias Recode.AST
  alias Recode.Issue
  alias Recode.Source
  alias Recode.Task.AliasOrder
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, opts) do
    do_run(source, opts[:autocorrect])
  end

  defp do_run(source, true) do
    {zipper, []} =
      source
      |> Source.zipper()
      |> Zipper.traverse_while([], fn zipper, acc ->
        alias_order(zipper, acc)
      end)

    Source.update(source, AliasOrder, code: zipper)
  end

  defp do_run(source, false) do
    {_zipper, groups} =
      source
      |> Source.zipper()
      |> Zipper.traverse_while([[]], fn zipper, acc ->
        alias_groups(zipper, acc)
      end)

    issues = issues(groups)

    Source.add_issues(source, issues)
  end

  defp alias_groups({{:alias, _meta, _args} = ast, _zipper_meta} = zipper, [group | groups]) do
    group = [ast | group]

    case AST.get_newlines(ast) do
      1 ->
        {:skip, zipper, [group | groups]}

      _newlines ->
        {:skip, zipper, [[], Enum.reverse(group) | groups]}
    end
  end

  defp alias_groups(zipper, [[] | _groups] = acc) do
    {:cont, zipper, acc}
  end

  defp alias_groups(zipper, [group | groups]) do
    {:cont, zipper, [[], Enum.reverse(group) | groups]}
  end

  defp issues([[] | groups]) do
    Enum.concat(
      Enum.flat_map(groups, &issues_in_group/1),
      Enum.flat_map(groups, &issues_in_multi/1)
    )
  end

  defp issues_in_group(group) do
    group
    |> unordered()
    |> Enum.map(&issue/1)
  end

  defp issues_in_multi(group) do
    Enum.reduce(group, [], fn
      {:alias, _meta1, [{{:., _meta2, _args2}, _meta3, multi}]}, acc ->
        multi
        |> unordered()
        |> Enum.map(&issue/1)
        |> Enum.concat(acc)

      _ast, acc ->
        acc
    end)
  end

  defp issue({:__aliases__, meta, args}) do
    Issue.new(
      AliasOrder,
      "The alias `#{AST.name(args)}` is not alphabetically ordered among its multi group",
      meta
    )
  end

  defp issue({:alias, meta, _args} = ast) do
    {name, _multi, _as} = AST.alias_info(ast)

    Issue.new(
      AliasOrder,
      "The alias `#{AST.name(name)}` is not alphabetically ordered among its group",
      meta
    )
  end

  defp unordered(group) do
    sorted = Enum.sort(group, &sort/2)

    sorted
    |> List.myers_difference(group)
    |> Enum.reduce([], fn
      {:del, alias}, acc -> Enum.concat(alias, acc)
      _eq_ins, acc -> acc
    end)
  end

  defp alias_order({{:alias, _meta, _args} = ast, _zipper_meta} = zipper, acc) do
    acc = [ast | acc]

    case AST.get_newlines(ast) do
      1 ->
        {:skip, zipper, acc}

      _newlines ->
        zipper = update(zipper, acc)
        {:skip, zipper, []}
    end
  end

  defp alias_order(zipper, []) do
    {:cont, zipper, []}
  end

  defp alias_order(zipper, acc) do
    zipper = update(zipper, acc)

    {:cont, zipper, []}
  end

  defp update(zipper, acc) do
    acc = Enum.reverse(acc)
    sorted = acc |> Enum.map(&sort_multi/1) |> Enum.sort(&sort/2)

    case acc == sorted do
      true ->
        zipper

      false ->
        zipper
        |> rewind(hd(acc))
        |> do_update(sorted)
    end
  end

  defp do_update(zipper, [ast]) do
    do_update(zipper, ast, 2)
  end

  defp do_update(zipper, [ast | sorted]) do
    zipper
    |> do_update(ast, 1)
    |> do_update(sorted)
  end

  defp do_update(zipper, ast, newlines) do
    zipper
    |> Zipper.update(fn _ast -> AST.put_newlines(ast, newlines) end)
    |> skip()
  end

  defp sort({:alias, _meta1, _args1} = alias1, {:alias, _meta2, _args2} = alias2) do
    {module1, multi1, _as} = AST.alias_info(alias1)
    {module2, multi2, _as} = AST.alias_info(alias2)

    case module1 == module2 do
      true -> length(multi1) < length(multi2)
      false -> module1 < module2
    end
  end

  defp sort({:__aliases__, _meta1, args1}, {:__aliases__, _meta2, args2}) do
    args1 < args2
  end

  defp sort_multi({:alias, meta1, [{{:., meta2, [aliases, opts]}, meta3, multi}]}) do
    multi =
      Enum.sort(multi, fn multi1, multi2 ->
        AST.aliases_concat(multi1) < AST.aliases_concat(multi2)
      end)

    {:alias, meta1, [{{:., meta2, [aliases, opts]}, meta3, multi}]}
  end

  defp sort_multi(ast), do: ast

  defp rewind(zipper, ast) do
    Zipper.find(zipper, :prev, fn item -> item == ast end)
  end

  # NOTE: Will be obsolete when the PR is accepted in the sourceror repo.
  #       The PR will fix Zipper.skip/2
  defp skip(zipper) do
    with nil <- Zipper.right(zipper) do
      Zipper.next(zipper)
    end
  end
end
