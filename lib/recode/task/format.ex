defmodule Recode.Task.Format do
  @moduledoc """
  This task runs the Elixir formatter.

  This task runs as first task by any `mix recode` call.
  """

  use Recode.Task, correct: true, check: true

  alias Recode.DotFormatter
  alias Recode.Issue
  alias Recode.Source
  alias Recode.Task.Format

  def run(source, opts) do
    format(source, opts[:autocorrect])
  end

  defp format(source, true) do
    code = format(source)
    Source.update(source, Format, code: code)
  end

  defp format(source, false) do
    code = format(source)

    case Source.code(source) == code <> "\n" do
      true ->
        source

      false ->
        Source.add_issue(source, Issue.new(Format, "The file is not formatted."))
    end
  end

  defp format(source) do
    source
    |> Source.code()
    |> Code.format_string!(DotFormatter.opts())
    |> IO.iodata_to_binary()
  end
end
