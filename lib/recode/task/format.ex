defmodule Recode.Task.Format do
  @shortdoc "Does the same as `mix format`."

  @moduledoc """
  This task runs the Elixir formatter.

  This task runs as first task by any `mix recode` call.
  """

  use Recode.Task, corrector: true, category: :readability

  alias Recode.Issue
  alias Recode.Task.Format
  alias Rewrite.Source

  @default_config [formatter: :sourceror]
  @valid_formatters [:elixir, :sourceror]

  @impl Recode.Task
  def run(source, opts) do
    source
    |> Source.Ex.merge_formatter_opts(exclude_plugins: [Recode.FormatterPlugin])
    |> execute(opts[:autocorrect], opts[:formatter])
  end

  defp execute(source, true, formatter) do
    Source.update(source, Format, :content, format(source, formatter))
  end

  defp execute(source, false, formatter) do
    case Source.get(source, :content) == format(source, formatter) do
      true ->
        source

      false ->
        Source.add_issue(source, Issue.new(Format, "The file is not formatted."))
    end
  end

  defp format(source, :sourceror) do
    Source.Ex.format(source)
  end

  defp format(source, :elixir) do
    opts = Keyword.get(source.filetype.opts, :formatter_opts, [])

    source
    |> Source.get(:content)
    |> Code.format_string!(opts)
    |> IO.iodata_to_binary()
  end

  @impl Recode.Task
  def init([]), do: {:ok, @default_config}

  def init(config) do
    with {:error, reason} <- validate(config) do
      case reason do
        {:unknown, keys} ->
          {:error,
           """
           Unknown options: #{inspect(keys)}.\
           """}

        {:invalid_formatter, formatter} ->
          {:error,
           """
           The option formatter expects :elixir or :sourceror, got: #{inspect(formatter)}.\
           """}
      end
    end
  end

  defp validate(config) do
    with {:ok, config} <- validate_keys(config) do
      if config[:formatter] in @valid_formatters do
        {:ok, config}
      else
        {:error, {:invalid_formatter, config[:formatter]}}
      end
    end
  end

  defp validate_keys(config) do
    with {:error, keys} <- Keyword.validate(config, @default_config) do
      {:error, {:unknown, keys}}
    end
  end
end
