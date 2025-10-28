defmodule Recode.Task.UnnecessaryIfUnless do
  @shortdoc "Removes redundant booleans"

  @moduledoc """
  Redundant booleans make code needlessly verbose.

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

  alias Rewrite.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, opts) do
    {zipper, issues} =
      source
      |> Source.get(:quoted)
      |> Zipper.zip()
      |> Zipper.traverse([], fn zipper, issues ->
        remove_unnecessary_if_unless(zipper, issues, opts[:autocorrect])
      end)

    update_source(source, opts, quoted: zipper, issues: issues)
  end

  defp remove_unnecessary_if_unless(
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

  defp remove_unnecessary_if_unless(
         %Zipper{node: {conditional, meta, body}} = zipper,
         issues,
         false
       )
       when conditional in [:if, :unless] do
    issues =
      case extract(body, conditional) do
        {:ok, _expr} ->
          message = "Avoid unnecessary `if` and `unless`"
          issue = new_issue(message, meta)
          [issue | issues]

        :error ->
          issues
      end

    {zipper, issues}
  end

  defp remove_unnecessary_if_unless(zipper, issues, _autocorrect), do: {zipper, issues}

  defp extract(
         [
           expr,
           [
             {{:__block__, _, [:do]}, {:__block__, _, [left]}},
             {{:__block__, _, [:else]}, {:__block__, _, [right]}}
           ]
         ],
         conditional
       )
       when is_boolean(left) and is_boolean(right) do
    case {conditional, left, right} do
      {:if, true, false} -> {:ok, expr}
      {:if, false, true} -> {:ok, {:not, [], [expr]}}
      {:unless, true, false} -> {:ok, {:not, [], [expr]}}
      {:unless, false, true} -> {:ok, expr}
    end
  end

  defp extract(_, _), do: :error

  defp put_leading_comments(expr, meta) do
    comments = meta[:leading_comments] || []
    Sourceror.append_comments(expr, comments)
  end
end
