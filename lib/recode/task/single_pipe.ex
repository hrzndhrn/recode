defmodule Recode.Task.SinglePipe do
  @moduledoc """
  Add parentheses to one-arity functions.
  """

  use Recode.Task, correct: true

  alias Recode.Project
  alias Recode.Source
  alias Recode.Task.SinglePipe
  alias Sourceror.Zipper

  def run(project, _opts) do
    Project.map(project, fn source ->
      zipper =
        source
        |> Source.zipper!()
        |> Zipper.traverse(&single_pipe/1)

      source = Source.update(source, SinglePipe, zipper: zipper)

      {:ok, source}
    end)
  end

  defp single_pipe({{:|>, _meta1, [{:|>, _meta2, _args}, _ast]}, _zipper_meta} = zipper) do
    skip(zipper)
  end

  defp single_pipe({{:|>, _meta1, _ast}, _zipper_meta} = zipper) do
    Zipper.update(zipper, &update/1)
  end

  defp single_pipe(zipper), do: zipper

  defp skip({{:|>, _meta1, _ast}, _zipper_meta} = zipper) do
    zipper |> Zipper.next() |> skip()
  end

  defp skip(zipper), do: zipper

  defp update({:|>, _meta, [arg, {fun, meta, args}]}) do
    {fun, meta, [arg | args]}
  end
end
