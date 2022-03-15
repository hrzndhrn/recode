defmodule Recode.Task.SinglePipe do
  @moduledoc """
  Pipes (`|>`) should only be used when piping data through multiple calls.

      # preferred
      some_string |> String.downcase() |> String.trim()
      Enum.reverse(some_enum)

      # not preferred
      some_enum |> Enum.reverse()

  This task rewrites the code when `mix recode` runs with `autocorrect: true`.
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

      source = Source.update(source, SinglePipe, code: zipper)

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
