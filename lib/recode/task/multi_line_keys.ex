defmodule Recode.Task.MultiLineKeys do
  use Recode.Task, correct: true, check: false

  alias Recode.AST
  alias Recode.Task.MultiLineKeys
  alias Rewrite.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, _opts) do
    zipper =
      source
      |> Source.ast()
      |> Zipper.zip()
      |> Zipper.traverse(&traverse/1)

    Source.update(source, MultiLineKeys, ast: Zipper.root(zipper))
  end

  defp traverse({{:%{}, map_meta, items_ast}, _zipper_meta} = zipper) do
    children = Zipper.children(items_ast)

    cond do
      AST.multiline?(map_meta) -> zipper
      length(children) <= 1 -> zipper
      true -> Zipper.update(zipper, &to_multi_line(&1, length(children)))
    end
  end

  defp traverse({values, _zipper_meta} = zipper) when is_list(values) do
    {_, meta, _} = zipper |> Zipper.up() |> Zipper.node()


    if AST.multiline?(meta) do
      zipper
    else
      zipper
      |> Zipper.up()
      |> Zipper.update(&to_multi_line(&1, length(values)))
    end
  end

  defp traverse(zipper) do
    zipper
  end

  defp to_multi_line({op, meta, ast}, lines_to_add) do
    current_closing_line = meta[:closing][:line] || meta[:line]
    updated_closing_line = current_closing_line + lines_to_add
    updated_newlines = lines_to_add

    updated_meta =
      meta
      |> Keyword.put(:closing, line: updated_closing_line)
      |> Keyword.put(:newlines, updated_newlines)

    {op, updated_meta, ast}
  end
end
