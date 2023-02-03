defmodule Recode.Task.Format do
  @moduledoc """
  This task runs the Elixir formatter.

  This task runs as first task by any `mix recode` call.
  """

  use Recode.Task, correct: true, check: true

  alias Recode.Issue
  alias Recode.Task.Format
  alias Rewrite.Source

  @impl Recode.Task
  def run(source, opts) do
    format(source, opts[:autocorrect])
  end

  defp format(source, true) do
    code = format(source)
    Source.update(source, Format, code: code)
  end

  defp format(source, false) do
    code = format(source)

    case Source.code(source) == code do
      true ->
        source

      false ->
        Source.add_issue(source, Issue.new(Format, "The file is not formatted."))
    end
  end

  defp format(source) do
    {formatter, _opts} = Mix.Tasks.Format.formatter_for_file(Source.path(source) || "elixir.ex")

    source
    |> Source.code()
    |> formatter.()
  end
end
