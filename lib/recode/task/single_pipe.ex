defmodule Recode.Task.SinglePipe do
  @moduledoc """
  Add parentheses to one-arity functions.
  """

  use Recode.Task.Source

  def run(quoted, _opts) do
    Zipper.zip(quoted)
    |> Zipper.traverse(&single_pipe/1)
    |> Zipper.root()
  end

  defp single_pipe({{:|>, _meta1, [{:|>, _meta2, _args}, _ast]}, _zipper_meta} = zipper) do
    Zipper.next(zipper)
  end

  defp single_pipe({{:|>, _meta1, _ast}, _zipper_meta} = zipper) do
    Zipper.update(zipper, &update/1)
  end

  defp single_pipe(zipper), do: zipper

  defp update({:|>, _meta, [arg, {fun, meta, args}]}) do
    {fun, meta, [arg | args]}
  end
end
