defmodule Recode.Task.Nesting do
  @moduledoc """
  Code should be not nested to deep in functions and macros.

  Developers should refactor a too-deeply nested function/macro by extracting
  branches from the code to separate functions to separate different loops and
  conditions.

  ## Options

    * `:max_depth` - the maximum allowable depth, defaults to `2`.

  """

  @shortdoc "Checks code nesting depth in functions and macros."

  use Recode.Task, category: :refactor

  alias Recode.Issue
  alias Recode.Task.Nesting
  alias Rewrite.Source
  alias Sourceror.Zipper

  @def_ops [:def, :defp, :defmacro, :defmacrop]
  @depth_ops [:if, :unless, :case, :cond, :fn]
  @max_depth 2

  @impl Recode.Task
  def run(source, opts) do
    source
    |> Source.get(:quoted)
    |> Zipper.zip()
    |> Zipper.traverse_while([], traverse_defs(opts[:max_depth]))
    |> update(source)
  end

  @impl Recode.Task
  def init(opts) do
    {:ok, Keyword.put_new(opts, :max_depth, @max_depth)}
  end

  defp update({_zipper, issues}, source) do
    Source.add_issues(source, issues)
  end

  defp traverse_defs(max_depth) do
    fn zipper, issues -> traverse_defs(zipper, issues, max_depth) end
  end

  defp traverse_defs({{op, _, _}, _zipper} = zipper, issues, max_depth)
       when op in @def_ops do
    {:skip, zipper, check_depth(zipper, issues, max_depth, 0)}
  end

  defp traverse_defs(zipper, issues, _max_depth), do: {:cont, zipper, issues}

  defp traverse_depth({{op, _, args}, _zipper_meat} = zipper, {issues, depth}, max_depth)
       when op in @depth_ops and depth < max_depth do
    issues = args |> Zipper.zip() |> check_depth(issues, max_depth, depth + 1)
    {:skip, zipper, {issues, 0}}
  end

  defp traverse_depth({{op, meta, _}, _zipper_meat} = zipper, {issues, _depth}, max_depth)
       when op in @depth_ops do
    issue = Issue.new(Nesting, "The body is nested too deep (max depth: #{max_depth}).", meta)
    {:skip, zipper, {[issue | issues], 0}}
  end

  defp traverse_depth(zipper, acc, _max_depth), do: {:cont, zipper, acc}

  defp check_depth(zipper, issues, max_depth, depth) do
    {_zipper, {issues, _depth}} =
      Zipper.traverse_while(zipper, {issues, depth}, fn zipper, acc ->
        traverse_depth(zipper, acc, max_depth)
      end)

    issues
  end
end
