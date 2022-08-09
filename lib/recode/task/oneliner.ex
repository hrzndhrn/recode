defmodule Recode.Task.Oneliner do
  @moduledoc """
  TODO: Add doc
  """

  use Recode.Task, correct: true, check: false

  alias Recode.Source
  alias Recode.Task.SinglePipe
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, _opts) do
    zipper =
      source
      |> Source.zipper()
      |> Zipper.traverse(&oneliner/1)

    Source.update(source, SinglePipe, code: zipper)
  end

  defp oneliner({{:def, meta, _args} = ast, _zipper_meta} = zipper) do
    ast = put_line(ast, meta[:line])
    Zipper.replace(zipper, ast)
  end

  defp oneliner({{name, meta, args}, _zipper_meta} = zipper) do
    case Keyword.has_key?(meta, :newlines) do
      false ->
        zipper

      true ->
        meta = Keyword.delete(meta, :newlines)
        Zipper.replace(zipper, {name, meta, args})
    end
  end

  defp oneliner(zipper), do: zipper

  defp put_line(ast, line) do
    ast
    |> Zipper.zip()
    |> Zipper.traverse(fn
      {{name, meta, args}, _zipper_meta} = zipper ->
        meta = meta |> Keyword.delete(:newlines) |> Keyword.put(:line, line)
        Zipper.replace(zipper, {name, meta, args})

      zipper ->
        zipper
    end)
    |> elem(0)
  end
end
