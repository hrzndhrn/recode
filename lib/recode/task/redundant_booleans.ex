defmodule Recode.Task.RedundantBooleans do
  @shortdoc "Removes redundant booleans"

  @moduledoc """
  Redudant booleans make code needlesly verbose.

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

  alias Recode.Issue
  alias Recode.Task.RedundantBooleans
  alias Rewrite.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, opts) do
    {zipper, issues} =
      source
      |> Source.get(:quoted)
      |> Zipper.zip()
      |> Zipper.traverse([], fn zipper, issues ->
        collapse_redundant_booleans(zipper, issues, opts[:autocorrect])
      end)

    case opts[:autocorrect] do
      true ->
        Source.update(source, RedundantBooleans, :quoted, Zipper.root(zipper))

      false ->
        Source.add_issues(source, issues)
    end
  end

  defp collapse_redundant_booleans(
         %Zipper{node: {conditional, meta, body}} = zipper,
         issues,
         true
       )
       when conditional in [:if, :unless] do
    case extract(body, conditional) do
      {:ok, expr} ->
        expr = put_leading_comments(expr, meta)

        {Zipper.replace(zipper, expr), issues}

      :error ->
        {zipper, issues}
    end
  end

  defp collapse_redundant_booleans(
         %Zipper{node: {conditional, meta, body}} = zipper,
         issues,
         false
       )
       when conditional in [:if, :unless] do
    issues =
      case extract(body, conditional) do
        {:ok, _expr} ->
          message = "Avoid `do: true, else: false`"
          issue = Issue.new(RedundantBooleans, message, meta)
          [issue | issues]

        :error ->
          issues
      end

    {zipper, issues}
  end

  defp collapse_redundant_booleans(zipper, issues, _autocorrect), do: {zipper, issues}

  defp extract([
         expr,
         [
           {{:__block__, _, [:do]}, {:__block__, _, [true]}},
           {{:__block__, _, [:else]}, {:__block__, _, [false]}}
         ]
       ], :if) do
    {:ok, expr}
  end

  defp extract([
         expr,
         [
           {{:__block__, _, [:do]}, {:__block__, _, [false]}},
           {{:__block__, _, [:else]}, {:__block__, _, [true]}}
         ]
       ], :unless) do
    {:ok, expr}
  end

  defp extract([
         expr,
         [
           {{:__block__, _, [:do]}, {:__block__, _, [false]}},
           {{:__block__, _, [:else]}, {:__block__, _, [true]}}
         ]
       ], :if) do
    {:ok, {:not, [], [expr]}}
  end

  defp extract([
         expr,
         [
           {{:__block__, _, [:do]}, {:__block__, _, [true]}},
           {{:__block__, _, [:else]}, {:__block__, _, [false]}}
         ]
       ], :unless) do
    {:ok, {:not, [], [expr]}}
  end

  defp extract(_, _), do: :error

  defp put_leading_comments(expr, meta) do
    comments = meta[:leading_comments] || []
    Sourceror.append_comments(expr, comments)
  end
end
