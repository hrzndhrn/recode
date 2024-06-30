defmodule Recode.Task.RemoveParens do
  @shortdoc "Removes parens from locals without parens"

  @moduledoc """
  Don't use parens for functions that don't need them.

          # preferred
          assert true == true

          # not preferred
          assert(true == true)

  This task rewrites the code when `mix recode` runs with `autocorrect: true`.
  """

  use Recode.Task, corrector: true, category: :readability

  alias Recode.Issue
  alias Recode.Task.RemoveParens
  alias Rewrite.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, opts) do
    formatter_opts = Mix.Tasks.Format.formatter_opts_for_file(source.path || "nofile")
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
         %Zipper{node: {fun, meta, args}} = zipper,
         issues,
         autocorrect?
       ) do
    if local_without_parens?(locals_without_parens, fun, args) do
      if autocorrect? do
        node = {fun, Keyword.delete(meta, :closing), args}
        {Zipper.replace(zipper, node), issues}
      else
        issue = Issue.new(RemoveParens, "Unncecessary parens")
        {zipper, [issue | issues]}
      end
    else
      {zipper, issues}
    end
  end

  defp remove_parens(_, zipper, issues, _) do
    {zipper, issues}
  end

  defp local_without_parens?(locals_without_parens, fun, [_ | _] = args) do
    arity = length(args)

    Enum.any?(locals_without_parens, fn
      {^fun, :*} -> true
      {^fun, ^arity} -> true
      _other -> false
    end)
  end

  defp local_without_parens?(_locals_without_parens, _fun, _args), do: false
end
