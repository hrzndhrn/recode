defmodule Recode.Task.PipeFunOne do
  @moduledoc """
  Add parentheses to one-arity functions.

      # preferred
      some_string |> String.downcase() |> String.trim()

      # not preferred
      some_string |> String.downcase |> String.trim

  This task rewrites the code when `mix recode` runs with `autocorrect: true`.
  """

  use Recode.Task, correct: true

  alias Recode.Project
  alias Recode.Source
  alias Recode.Task.PipeFunOne
  alias Sourceror.Zipper

  def run(project, _opts) do
    Project.map(project, fn source ->
      zipper =
        source
        |> Source.zipper!()
        |> Zipper.traverse(&pipe_fun_one/1)

      source = Source.update(source, PipeFunOne, code: zipper)

      {:ok, source}
    end)
  end

  defp pipe_fun_one({{:|>, _meta, _tree}, _} = zipper) do
    Zipper.update(zipper, &update/1)
  end

  defp pipe_fun_one(zipper), do: zipper

  defp update({:|>, meta, [a, b]}) do
    {:|>, meta, [a, update(b)]}
  end

  defp update({name, meta, nil}) do
    {name, meta, []}
  end

  defp update(tree), do: tree
end
