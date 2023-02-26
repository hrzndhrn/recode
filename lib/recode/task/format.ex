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
    formatter = formatter(source)

    source
    |> Source.code()
    |> formatter.()
  end

  defp formatter(source) do
    file = Source.path(source) || "elixir.ex"
    ext = Path.extname(file)

    {formatter, formatter_opts} = Mix.Tasks.Format.formatter_for_file(file)

    case Keyword.get(formatter_opts, :plugins, []) do
      [] ->
        formatter

      [Recode.FormatterPlugin] ->
        fn content -> elixir_format(content, formatter_opts) end

      plugins ->
        plugins = plugins_for_ext(plugins, ext, formatter_opts)
        formatter_opts = [extension: ext, file: file] ++ formatter_opts
        fn content -> plugins_format(plugins, content, formatter_opts) end
    end
  end

  defp elixir_format(content, formatter_opts) do
    case Code.format_string!(content, formatter_opts) do
      [] -> ""
      formatted_content -> IO.iodata_to_binary([formatted_content, ?\n])
    end
  end

  defp plugins_format(plugins, content, formatter_opts) do
    Enum.reduce(plugins, content, fn plugin, content ->
      plugin.format(content, formatter_opts)
    end)
  end

  defp plugins_for_ext([_ | _] = plugins, ext, formatter_opts) do
    Enum.filter(plugins, fn
      Recode.FormatterPlugin ->
        false

      plugin ->
        Code.ensure_loaded?(plugin) and function_exported?(plugin, :features, 1) and
          ext in List.wrap(plugin.features(formatter_opts)[:extensions])
    end)
  end
end
