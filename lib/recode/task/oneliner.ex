defmodule Recode.Task.Oneliner do
  @moduledoc """
  TODO: Add doc
  """

  use Recode.Task, correct: true, check: false

  alias Recode.AST
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

  defp oneliner({{_expr, meta, _args} = ast, _zipper_meta} = zipper) do
    case AST.multiline?(meta) do
      false -> zipper
      true -> Zipper.replace(zipper, AST.to_same_line(ast))
    end
  end

  defp oneliner(zipper), do: zipper
end
