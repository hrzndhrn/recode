defmodule Recode.Task.Comparisons do
  @shortdoc "Removes extraneous conditionals"

  @moduledoc """
  Multi aliases makes module uses harder to search for in large code bases.

          # preferred
          foo == bar

          # not preferred
          if foo == bar do
            true
          else
            false
          end

  This task rewrites the code when `mix recode` runs with `autocorrect: true`.
  """

  use Recode.Task, corrector: true, category: :readability

  # alias Recode.Issue
  alias Recode.Task.Comparisons
  alias Rewrite.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, opts) do
    {zipper, issues} =
      source
      |> Source.get(:quoted)
      |> Zipper.zip()
      |> Zipper.traverse([], fn zipper, issues ->
        simplify_comparison(zipper, issues, opts[:autocorrect])
      end)

    case opts[:autocorrect] do
      true ->
        Source.update(source, Comparisons, :quoted, Zipper.root(zipper))

      false ->
        Source.add_issues(source, issues)
    end
  end

  defp simplify_comparison(%Zipper{node: {conditional, _, args}} = zipper, issues, true)
       when conditional == :if do
    case args do
      [
        expr,
        [
          {{:__block__, _, [:do]},
           {:__block__, _, [true]}},
          {{:__block__, _, [:else]},
           {:__block__, _, [false]}}
        ]
      ] ->
        {Zipper.replace(zipper, expr), issues}

      _ ->
        {zipper, issues}
    end
  end

  defp simplify_comparison(
         %Zipper{node: {conditional, _, _args} = _ast} = zipper,
         issues,
         false
       )
       when conditional in [:if, :unless] do
    {zipper, issues}
  end

  defp simplify_comparison(zipper, issues, _autocorrect), do: {zipper, issues}
end
