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
    source
    |> Source.Ex.merge_formatter_opts(exclude_plugins: [Recode.FormatterPlugin])
    |> format(opts[:autocorrect])
  end

  defp format(source, true) do
    Source.update(source, Format, :content, Source.Ex.format(source))
  end

  defp format(source, false) do
    case Source.get(source, :content) == Source.Ex.format(source) do
      true ->
        source

      false ->
        Source.add_issue(source, Issue.new(Format, "The file is not formatted."))
    end
  end
end
