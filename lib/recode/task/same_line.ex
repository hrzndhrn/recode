defmodule Recode.Task.SameLine do
  @moduledoc """
  TODO: Add doc
  """

  use Recode.Task, correct: true, check: false

  alias Recode.AST
  alias Recode.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, _opts) do
    zipper =
      source
      |> Source.zipper()
      |> Zipper.traverse(&oneliner/1)

    Source.update(source, SameLine, code: zipper)
  end

  defp oneliner({{_name, _meta, args}, _zipper_meta} = zipper) when is_list(args) do
    case zipper |> Zipper.node() |> AST.multiline?() do
      true -> Zipper.update(zipper, &AST.to_same_line/1)
      false -> zipper
    end
  end

  defp oneliner(zipper), do: zipper
end
