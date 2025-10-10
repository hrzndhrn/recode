defmodule Recode.Task.AliasOrder do
  @shortdoc "Checks if aliases are sorted alphabetically."

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

  use Recode.Task, corrector: true, category: :readability

  alias Recode.AST
  alias Rewrite.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, opts) do
    source
    |> Source.get(:quoted)
    |> Zipper.zip()
    |> do_run(source, opts[:autocorrect], opts)
  end

  defp do_run(zipper, source, false, opts) do
    {_zipper, groups} =
      Zipper.traverse_while(zipper, [[]], fn zipper, acc ->
        alias_groups(zipper, acc)
      end)

    update_source(source, opts, issues: issues(groups))
  end

  defp do_run(zipper, source, true, opts) do
    {zipper, []} =
      Zipper.traverse_while(zipper, [], fn zipper, acc ->
        alias_order(zipper, acc)
      end)

    update_source(source, opts, quoted: zipper)
  end

  defp alias_groups(%Zipper{node: {:alias, _meta, _args} = ast} = zipper, [group | groups]) do
    group = [ast | group]

    if AST.get_newlines(ast) > 1 || !Zipper.skip(zipper) do
      {:skip, zipper, [[], Enum.reverse(group) | groups]}
    else
      {:skip, zipper, [group | groups]}
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
    new_issue(
      "The alias `#{AST.name(args)}` is not alphabetically ordered among its multi group",
      meta
    )
  end

  defp issue({:alias, meta, _args} = ast) do
    {name, _multi, _as} = AST.alias_info(ast)

    new_issue(
      "The alias `#{AST.name(name)}` is not alphabetically ordered among its group",
      meta
    )
  end

  defp unordered(group) do
    group =
      Enum.reject(group, fn
        {:alias, _meta1, [{:unquote, _meta2, _args} | _rest]} -> true
        _alias -> false
      end)

    sorted = Enum.sort(group, &sort/2)

    sorted
    |> List.myers_difference(group)
    |> Enum.reduce([], fn
      {:del, alias}, acc -> Enum.concat(alias, acc)
      _eq_ins, acc -> acc
    end)
  end

  defp alias_order(%Zipper{node: {:alias, _meta, _args} = ast} = zipper, acc) do
    acc = [ast | acc]

    if AST.get_newlines(ast) > 1 || !Zipper.skip(zipper) do
      zipper = update(zipper, acc)
      {:skip, zipper, []}
    else
      {:skip, zipper, acc}
    end
  end

  defp alias_order(zipper, []) do
    {:cont, zipper, []}
  end

  defp alias_order(zipper, acc) do
    zipper = update(zipper, acc)

    {:cont, zipper, []}
  end

  # defp update(zipper, []), do: zipper
  #
  # defp update(zipper, [_alias]), do: zipper

  defp update(zipper, acc) do
    acc = Enum.reverse(acc)
    leading_comments = get_leading_comments(acc)

    sorted =
      acc
      |> Enum.map(&sort_multi/1)
      |> Enum.sort(&sort/2)

    case acc == sorted do
      true ->
        zipper

      false ->
        sorted = put_leading_comments(sorted, leading_comments)

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
      false -> lower_than?(module1, module2)
    end
  end

  defp sort({:__aliases__, _meta1, args1}, {:__aliases__, _meta2, args2}) do
    lower_than?(args1, args2)
  end

  defp lower_than?([value1], [value2]), do: lower_than?(value1, value2)

  defp lower_than?([_value], []), do: false

  defp lower_than?([], [_value]), do: true

  defp lower_than?([value | rest1], [value | rest2]), do: lower_than?(rest1, rest2)

  defp lower_than?([value1 | _], [value2 | _]), do: lower_than?(value1, value2)

  defp lower_than?(value1, value2) when is_atom(value1) and is_atom(value2) do
    String.upcase(to_string(value1)) < String.upcase(to_string(value2))
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

  defp skip(zipper) do
    with nil <- Zipper.right(zipper) do
      Zipper.next(zipper)
    end
  end

  defp get_leading_comments([{:alias, meta, _block} | _rest]) do
    Keyword.get(meta, :leading_comments, [])
  end

  defp put_leading_comments([{:alias, meta, block} | rest], comments) do
    rest =
      Enum.map(rest, fn {:alias, meta, block} ->
        {:alias, Keyword.put(meta, :leading_comments, []), block}
      end)

    [{:alias, Keyword.put(meta, :leading_comments, comments), block} | rest]
  end
end
