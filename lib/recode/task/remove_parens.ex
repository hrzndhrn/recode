defmodule Recode.Task.RemoveParens do
  @shortdoc "Removes parens from locals without parens"

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
  alias Recode.Task.RemoveParens
  alias Rewrite.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, opts) do
    formatter_opts = Mix.Tasks.Format.formatter_opts_for_file(".mix.exs")
    locals_without_parens = Keyword.get(formatter_opts, :locals_without_parens, [])

    {zipper, issues} =
      source
      |> Source.get(:quoted)
      |> Zipper.zip()
      |> Zipper.traverse([], fn zipper, issues ->
        remove_parens(locals_without_parens, zipper, issues, opts[:autocorrect])
      end)

    case opts[:autocorrect] do
      true ->
        Source.update(source, RemoveParens, :quoted, Zipper.root(zipper))

      false ->
        Source.add_issues(source, issues)
    end
  end

  defp remove_parens(
         locals_without_parens,
         %Zipper{node: {fun, _, args} = node} = zipper,
         issues,
         true
       ) do
    node =
      Enum.reduce(locals_without_parens, node, fn
        {^fun, arity}, node when length(args) == arity ->
          {fun, meta, args} = node
          meta = Keyword.delete(meta, :closing)

          {fun, meta, args}

        _, node ->
          node
      end)

    {%Zipper{zipper | node: node}, issues}
  end

  defp remove_parens(
         locals_without_parens,
         %Zipper{node: {fun, _, args}} = zipper,
         issues,
         false
       ) do
    issues =
      Enum.reduce(locals_without_parens, issues, fn
        {^fun, arity}, issues when length(args) == arity ->
          issue = Issue.new(RemoveParens, "Unncecessary parens")

          [issue | issues]

        _, issues ->
          issues
      end)

    {zipper, issues}
  end

  defp remove_parens(_, zipper, issues, _) do
    {zipper, issues}
  end
end
