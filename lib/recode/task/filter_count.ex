defmodule Recode.Task.FilterCount do
  @shortdoc "Checks calls like Enum.filter(...) |> Enum.count()."

  @moduledoc """
  `Enum.count/2` is more efficient than `Enum.filter/2 |> Enum.count/1`.


      # this should be refactored
      [1, 2, 3, 4, 5]
      |> Enum.filter(fn x -> rem(x, 3) == 0 end)
      |> Enum.count()

      # to look like this
      Enum.count([1, 2, 3, 4, 5], fn x -> rem(x, 3) == 0 end)

  The reason for this is performance, because the two separate calls to
  `Enum.filter/2` and `Enum.count/1` require two iterations whereas
  `Enum.count/2` performs the same work in one pass.

  This task rewrites the code when `mix recode` runs with `autocorrect: true`.
  """

  use Recode.Task, corrector: true, category: :refactor

  alias Recode.Issue
  alias Recode.Task.FilterCount
  alias Rewrite.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, opts) do
    source
    |> Source.get(:quoted)
    |> Zipper.zip()
    |> Zipper.traverse([], fn zipper, issues ->
      filter_count(zipper, issues, opts[:autocorrect])
    end)
    |> update(source, opts[:autocorrect])
  end

  defp update({zipper, _issues}, source, true) do
    Source.update(source, FilterCount, :quoted, Zipper.root(zipper))
  end

  defp update({_zipper, issues}, source, false) do
    Source.add_issues(source, issues)
  end

  defp filter_count(
         %Zipper{
           node:
             {:|>, _,
              [
                {{:., _, [{:__aliases__, _, [:Enum]}, :filter]}, _, [arg, fun]},
                {{:., meta, [{:__aliases__, _, [:Enum]}, :count]}, _, []}
              ]}
         } = zipper,
         issues,
         autocorrect
       ) do
    if autocorrect do
      {Zipper.replace(zipper, quoted_count(fun, arg)), issues}
    else
      {zipper, [issue(meta) | issues]}
    end
  end

  defp filter_count(
         %Zipper{
           node:
             {:|>, meta,
              [
                {:|>, _,
                 [
                   {expr, _, _} = arg,
                   {{:., issue_meta, [{:__aliases__, _, [:Enum]}, :filter]}, _, [fun]}
                 ]},
                {{:., _, [{:__aliases__, _, [:Enum]}, :count]}, _, []}
              ]}
         } = zipper,
         issues,
         autocorrect
       ) do
    if autocorrect do
      arg = prune_data(arg)
      fun = prune_data(fun)

      quoted =
        case expr do
          :|> ->
            quoted_count_pipe(fun, meta, arg)

          _else ->
            case in_pipe?(zipper) do
              true -> quoted_count_pipe(fun, meta, arg)
              false -> quoted_count(fun, arg)
            end
        end

      {Zipper.replace(zipper, quoted), issues}
    else
      {zipper, [issue(issue_meta) | issues]}
    end
  end

  defp filter_count(
         %Zipper{
           node:
             {{:., _, [{:__aliases__, _, [:Enum]}, :count]}, _,
              [
                {:|>, meta,
                 [{expr, _, _} = arg, {{:., _, [{:__aliases__, _, [:Enum]}, :filter]}, _, [fun]}]}
              ]}
         } = zipper,
         issues,
         autocorrect
       ) do
    if autocorrect do
      quoted =
        case expr do
          :|> -> quoted_count_pipe(fun, meta, arg)
          _else -> quoted_count(fun, arg)
        end

      {Zipper.replace(zipper, quoted), issues}
    else
      {zipper, [issue(meta) | issues]}
    end
  end

  defp filter_count(
         %Zipper{
           node:
             {{:., meta, [{:__aliases__, _, [:Enum]}, :count]}, _,
              [
                {{:., _, [{:__aliases__, _, [:Enum]}, :filter]}, _, [arg, fun]}
              ]}
         } = zipper,
         issues,
         autocorrect
       ) do
    if autocorrect do
      {Zipper.replace(zipper, quoted_count(fun, arg)), issues}
    else
      {zipper, [issue(meta) | issues]}
    end
  end

  defp filter_count(zipper, issues, _autocorrect), do: {zipper, issues}

  defp quoted_count(fun, arg) do
    {{:., [], [{:__aliases__, [], [:Enum]}, :count]}, [], [arg, fun]}
  end

  defp quoted_count_pipe(fun, meta, arg) do
    {:|>, meta, [arg, {{:., [], [{:__aliases__, [], [:Enum]}, :count]}, [], [fun]}]}
  end

  defp prune_data({expr, _meta, args}), do: {expr, [], args}

  defp in_pipe?(zipper) do
    match?({:|>, _, _}, zipper |> Zipper.up() |> Zipper.node())
  end

  defp issue(meta) do
    Issue.new(
      FilterCount,
      "`Enum.count/2` is more efficient than `Enum.filter/2 |> Enum.count/1`",
      meta
    )
  end
end
