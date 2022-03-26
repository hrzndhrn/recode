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

  use Recode.Task, correct: true, check: true

  alias Recode.Issue
  alias Recode.Project
  alias Recode.Source
  alias Recode.Task.SinglePipe
  alias Sourceror.Zipper

  def run(project, opts) do
    Project.map(project, fn source ->
      {zipper, issues} =
        source
        |> Source.zipper!()
        |> Zipper.traverse([], fn zipper, issues ->
          single_pipe(zipper, issues, opts[:autocorrect])
        end)

      source =
        source
        |> Source.update(SinglePipe, code: zipper)
        |> Source.add_issues(issues)

      {:ok, source}
    end)
  end

  defp single_pipe(
         ~z/{:|>, _meta1, [{:|>, _meta2, _args}, _ast]}/ = zipper,
         issues,
         _autocorrect
       ) do
    {skip(zipper), issues}
  end

  defp single_pipe(~z/{:|>, _meta, _ast}/ = zipper, issues, true) do
    {Zipper.update(zipper, &update/1), issues}
  end

  defp single_pipe(~z/{:|>, meta, _ast}/ = zipper, issues, false) do
    issue =
      Issue.new(
        SinglePipe,
        "Use a function call when a pipeline is only one function long.",
        meta
      )

    {zipper, [issue | issues]}
  end

  defp single_pipe(zipper, issues, _autocorrect), do: {zipper, issues}

  defp skip(~z/{:|>, _meta, _ast}/ = zipper) do
    zipper |> Zipper.next() |> skip()
  end

  defp skip(zipper), do: zipper

  defp update({:|>, _meta, [arg, {fun, meta, args}]}) do
    {fun, meta, [arg | args]}
  end
end
