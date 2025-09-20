defmodule Recode.Task.PipeFunOne do
  @shortdoc "Add parentheses to one-arity functions."

  @moduledoc """
  Add parentheses to one-arity functions.

      # preferred
      some_string |> String.downcase() |> String.trim()

      # not preferred
      some_string |> String.downcase |> String.trim

  This task rewrites the code when `mix recode` runs with `autocorrect: true`.
  """

  use Recode.Task, corrector: true, category: :readability

  alias Recode.Issue
  alias Rewrite.Source
  alias Sourceror.Zipper

  @defs [:def, :defp, :defmacro, :defmacrop, :defdelegate]

  @impl Recode.Task
  def run(source, opts) do
    {zipper, issues} =
      source
      |> Source.get(:quoted)
      |> Zipper.zip()
      |> Zipper.traverse([], fn zipper, issues ->
        pipe_fun_one(zipper, issues, opts[:autocorrect])
      end)

    case opts[:autocorrect] do
      true -> Source.update(source, :quoted, Zipper.root(zipper), by: __MODULE__)
      false -> Source.add_issues(source, issues)
    end
  end

  defp pipe_fun_one(%Zipper{node: {def, _meta, _args}} = zipper, issues, _autocorrect)
       when def in @defs do
    {Zipper.next(zipper), issues}
  end

  defp pipe_fun_one(%Zipper{node: {:|>, _meta, _tree}} = zipper, issues, true) do
    {Zipper.update(zipper, &update/1), issues}
  end

  defp pipe_fun_one(%Zipper{node: {:|>, meta, _tree} = ast} = zipper, issues, false) do
    case issue?(ast) do
      true ->
        issue = Issue.new(__MODULE__, "Use parentheses for one-arity functions in pipes.", meta)

        {zipper, [issue | issues]}

      false ->
        {zipper, issues}
    end
  end

  defp pipe_fun_one(zipper, issues, _autocorrect), do: {zipper, issues}

  defp issue?({:|>, _meta1, [_a, {_name, _meta2, nil}]}), do: true

  defp issue?({:|>, _meta1, [_a, {_name, meta, []}]}), do: Keyword.get(meta, :no_parens, false)

  defp issue?(_ast), do: false

  defp update({:|>, meta, [a, b]}) do
    {:|>, meta, [a, update(b)]}
  end

  defp update({name, meta, nil}) do
    {name, meta, []}
  end

  defp update({name, meta, []}) do
    {name, Keyword.delete(meta, :no_parens), []}
  end

  defp update(tree), do: tree
end
