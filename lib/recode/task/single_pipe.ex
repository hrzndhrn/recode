defmodule Recode.Task.SinglePipe do
  @shortdoc "Pipes should only be used when piping data through multiple calls."

  @moduledoc """
  Pipes (`|>`) should only be used when piping data through multiple calls.

      # preferred
      some_string |> String.downcase() |> String.trim()
      Enum.reverse(some_enum)

      # not preferred
      some_enum |> Enum.reverse()

  `SinglePipe` does not change a single `|>` that starts with a none zero arity
  function.

      # will not be changed
      one(:a) |> two()

  This task rewrites the code when `mix recode` runs with `autocorrect: true`.
  """

  use Recode.Task, corrector: true, category: :readability

  alias Rewrite.Source
  alias Sourceror.Zipper

  @defs [:def, :defp, :defmacro, :defmacrop, :defdelegate]

  @impl Recode.Task
  def run(source, opts) do
    source
    |> Source.get(:quoted)
    |> Zipper.zip()
    |> Zipper.traverse([], fn zipper, issues ->
      single_pipe(zipper, issues, opts[:autocorrect])
    end)
    |> update(source, opts)
  end

  defp update({zipper, issues}, source, opts) do
    update_source(source, opts, quoted: zipper, issues: issues)
  end

  defp single_pipe(%Zipper{node: {def, _meta, _args}} = zipper, issues, _autocorrect)
       when def in @defs do
    {Zipper.next(zipper), issues}
  end

  defp single_pipe(
         %Zipper{node: {:|>, _meta1, [{:|>, _meta2, _args}, _ast]}} = zipper,
         issues,
         _autocorrect
       ) do
    {skip(zipper), issues}
  end

  defp single_pipe(%Zipper{node: {:|>, _meta, _ast}} = zipper, issues, true) do
    zipper = zipper |> Zipper.update(&update/1) |> skip()

    {zipper, issues}
  end

  defp single_pipe(%Zipper{node: {:|>, meta, _ast}} = zipper, issues, false) do
    issue =
      new_issue(
        "Use a function call when a pipeline is only one function long.",
        meta
      )

    {zipper, [issue | issues]}
  end

  defp single_pipe(zipper, issues, _autocorrect), do: {zipper, issues}

  defp skip(%Zipper{node: {:|>, _meta, _ast}} = zipper) do
    zipper |> Zipper.next() |> skip()
  end

  defp skip(zipper), do: zipper

  defp update({:|>, _meta1, [{_name, _meta2, nil} = arg, {fun, meta, args}]}) do
    {fun, meta, [arg | args]}
  end

  defp update({:|>, _meta1, [{_name, _meta2, []} = arg, {fun, meta, args}]}) do
    {fun, meta, [arg | args]}
  end

  defp update({:|>, _meta1, [{:__block__, _meta2, [_arg]} = block, {fun, meta, args}]}) do
    {fun, meta, [block | args]}
  end

  defp update({:|>, _meta1, [{:%{}, _meta2, _args} = map, {fun, meta, args}]}) do
    {fun, meta, [map | args]}
  end

  # Single pipes with two function calls are not changed.
  # e.g. `foo(1) |> bar(2)`
  # Because we do not want: `bar(2, foo(1))`. Some other check should expand
  # this to `1 |> foo() |> bar(2)`.
  defp update(ast), do: ast
end
