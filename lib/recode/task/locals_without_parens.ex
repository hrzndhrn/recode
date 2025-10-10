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

  @def [:def, :defp, :defmacro, :defmacrop]
  @exclude [:{}, :%{}, :|>]

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
    |> Zipper.traverse_while([], fn zipper, issues ->
      remove_parens(zipper, issues, locals_without_parens, opts[:autocorrect])
    end)
    |> update(source, opts)
  end

  defp update({zipper, issues}, source, opts) do
    update_source(source, opts, quoted: zipper, issues: issues)
  end

  defp remove_parens(
         %Zipper{node: {{:__block__, meta, [:do]}, _block}} = zipper,
         issues,
         _locals_without_parens,
         _autocorrect?
       ) do
    if meta[:format] == :keyword do
      {:skip, zipper, issues}
    else
      {:cont, zipper, issues}
    end
  end

  defp remove_parens(
         %Zipper{node: {fun, _meta, _args}} = zipper,
         issues,
         _locals_without_parens,
         _autocorrect?
       )
       when fun in @def do
    {:cont, Zipper.next(zipper), issues}
  end

  defp remove_parens(
         %Zipper{node: {_one, _two}} = zipper,
         issues,
         _locals_without_parens,
         _autocorrect?
       ) do
    {:skip, zipper, issues}
  end

  defp remove_parens(
         %Zipper{node: {form, _meta, _args}} = zipper,
         issues,
         _locals_without_parens,
         _autocorrect?
       )
       when form in @exclude do
    {:skip, zipper, issues}
  end

  defp remove_parens(
         %Zipper{node: {_fun, _meta, [_ | _]}} = zipper,
         issues,
         locals_without_parens,
         autocorrect?
       ) do
    do_remove_parens(zipper, issues, locals_without_parens, autocorrect?)
  end

  defp remove_parens(zipper, issues, _locals_without_parens, _autocorrect) do
    {:cont, zipper, issues}
  end

  defp do_remove_parens(
         %Zipper{node: {fun, meta, args}} = zipper,
         issues,
         locals_without_parens,
         autocorrect?
       ) do
    if remove_parens?(fun, meta, args, locals_without_parens) do
      if autocorrect? do
        node = {fun, Keyword.delete(meta, :closing), args}
        {:cont, Zipper.replace(zipper, node), issues}
      else
        issue = new_issue("Unnecessary parens", meta)
        {:cont, zipper, [issue | issues]}
      end
    else
      {:cont, zipper, issues}
    end
  end

  defp remove_parens?(fun, meta, args, locals_without_parens) do
    Keyword.has_key?(meta, :closing) and not multiline?(meta) and
      local_without_parens?(locals_without_parens, fun, args)
  end

  defp local_without_parens?(locals_without_parens, fun, args) do
    arity = length(args)

    Enum.any?(locals_without_parens, fn
      {^fun, :*} -> true
      {^fun, ^arity} -> true
      _other -> false
    end)
  end

  defp multiline?(meta) do
    meta[:line] < meta[:closing][:line]
  end
end
