defmodule Recode.Task.KeysOrder do
  @moduledoc false
  use Recode.Task, correct: true, check: false

  alias Recode.Task.KeysOrder
  alias Rewrite.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, _opts) do
    zipper =
      source
      |> Source.ast()
      |> Zipper.zip()
      |> Zipper.traverse(&traverse/1)

    Source.update(source, KeysOrder, ast: Zipper.root(zipper))
  end

  defp traverse({values, _zipper_meta} = zipper) when is_list(values) do
    Zipper.update(zipper, &order_keys/1)
  end

  defp traverse({{:%{}, _meta, _ast}, _zipper_meta} = zipper) do
    Zipper.update(zipper, &order_keys/1)
  end

  defp traverse(zipper) do
    zipper
  end

  defp order_keys(values) when is_list(values) do
    Enum.sort_by(values, fn
      {{:__block__, _meta, [key]}, _value} -> to_string(key)
      _other -> false
    end)
  end

  defp order_keys({:%{}, meta, ast}) do
    sorted_keys =
      ast
      |> Zipper.children()
      |> Enum.sort_by(fn
        {{:__block__, _meta, [key]}, _value} -> to_string(key)
        _other -> false
      end)

    {:%{}, meta, sorted_keys}
  end
end
