defmodule Recode.Task.Format do
  @moduledoc """
  This task runs the Elixir formatter.

  This task runs as first task by any `mix recode` call.
  """

  use Recode.Task,
    correct: true,
    check: true,
    force_default_formatter: false

  alias Recode.Issue
  alias Recode.Task.Format
  alias Rewrite.Source

  @impl Recode.Task
  def run(source, opts) do
    {autocorrect?, opts} = Keyword.pop!(opts, :autocorrect)
    code = format(source, opts)

    cond do
      autocorrect? ->
        Source.update(source, Format, code: code)

      not autocorrect? and Source.code(source) == code ->
        source

      not autocorrect? ->
        Source.add_issue(source, Issue.new(Format, "The file is not formatted."))
    end
  end

  defp format(source, opts) do
    {formatter, _formatter_opts} =
      if opts[:force_default_formatter] do
        {&elixir_format/1, []}
      else
        Mix.Tasks.Format.formatter_for_file(Source.path(source) || "elixir.ex")
      end

    source
    |> Source.code()
    |> formatter.()
  end

  defp elixir_format(content) do
    case Code.format_string!(content, []) do
      [] -> ""
      formatted_content -> IO.iodata_to_binary([formatted_content, ?\n])
    end
  end
end
