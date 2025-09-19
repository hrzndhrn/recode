defmodule Recode.Task.Format do
  @shortdoc "Does the same as `mix format`."

  @moduledoc """
  This task runs the Elixir formatter.

  This task runs as first task by any `mix recode` call.
  """

  # The task can be configured like other tasks. This configuration is just for
  # debuging and not part of the documentation.
  #
  # The default, formats code with Sourceror:
  # {Recode.Task.Format, []},
  #
  # formats code with Sourceror:
  # {Recode.Task.Format, config: [formatter: :sourceror]},
  #
  # Formats code with the Elixir formatter:
  #  {Recode.Task.Format, config: [formatter: :elixir]},
  #
  # Deactivates the task:
  # {Recode.Task.Format, active: false},

  use Recode.Task, corrector: true, category: :readability

  alias Recode.Issue
  alias Recode.Task.Format
  alias Rewrite.DotFormatter
  alias Rewrite.Source

  @default_config [formatter: :sourceror]
  @valid_formatters [:elixir, :sourceror]

  @impl Recode.Task
  def run(source, opts) do
    opts = Keyword.merge(opts, @default_config)

    execute(source, opts[:autocorrect], opts[:formatter])
  end

  defp execute(source, true, formatter) do
    Source.update(source, :content, format(source, formatter), by: Format)
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
    formatter_opts = Keyword.get(source.filetype.opts, :formatter_opts, [])

    current_formatter_opts =
      case DotFormatter.read() do
        {:ok, dot_formatter} -> DotFormatter.formatter_opts(dot_formatter)
        {:error, _reason} -> []
      end

    merged_formatter_opts = Keyword.merge(current_formatter_opts, formatter_opts)

    dot_formatter =
      DotFormatter.from_formatter_opts(merged_formatter_opts,
        remove_plugins: [Recode.FormatterPlugin]
      )

    path = Map.get(source, :path) || Source.default_path(source)

    DotFormatter.format_string!(dot_formatter, path, source.content)
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
    with {:error, keys} <- Keyword.validate(config, [:autocorrect] ++ @default_config) do
      {:error, {:unknown, keys}}
    end
  end
end
