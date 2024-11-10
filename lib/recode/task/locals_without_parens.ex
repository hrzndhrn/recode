defmodule Recode.Task.LocalsWithoutParens do
  @shortdoc "Removes parens from locals without parens."

  @moduledoc """
  Don't use parens for functions that don't need them.

          # preferred
          assert true == true

          # not preferred
          assert(true == true)

  The task uses the `:locals_without_parens` from the formatter config in `.formatter.exs`.
  See also: ["Importing-dependencies-configuration"](https://hexdocs.pm/mix/Mix.Tasks.Format.html#module-importing-dependencies-configuration)
  in the docs for [`mix format`](https://hexdocs.pm/mix/Mix.Tasks.Format.html#content).

  This task rewrites the code when `mix recode` runs with `autocorrect: true`.
  """

  use Recode.Task, corrector: true, category: :readability

  alias Rewrite.DotFormatter
  alias Rewrite.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, opts) do
    locals_without_parens =
      opts
      |> Keyword.fetch!(:dot_formatter)
      |> DotFormatter.formatter_opts_for_file(source.path || "nofile")
      |> Keyword.get(:locals_without_parens, [])
      |> Enum.concat(Code.Formatter.locals_without_parens())

    source
    |> Source.get(:quoted)
    |> Zipper.zip()
    |> Zipper.traverse([], fn zipper, issues ->
      remove_parens(locals_without_parens, zipper, issues, opts[:autocorrect])
    end)
    |> update(source, opts)
  end

  defp update({zipper, issues}, source, opts) do
    update_source(source, opts, quoted: zipper, issues: issues)
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
        issue = new_issue("Unnecessary parens")
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
