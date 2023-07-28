defmodule Recode.Config do
  @moduledoc """
  This module reads the `Recode` configuration.
  """

  alias Recode.Task.Format

  @type config :: keyword()

  @config_filename ".recode.exs"

  @config_version "0.6.0"

  # The minimum version of the config to run recode. This version marks the last
  # breaking change for handle the config.
  @config_min_version "0.6.0"

  @config_keys [:version, :autocorrect, :dry, :verbose, :inputs, :formatter, :tasks]

  # The default configuration used by mix tasks recode.gen.config and
  # recode.update.config.
  @config_default [
    version: @config_version,
    autocorrect: true,
    dry: false,
    verbose: false,
    inputs: ["{mix,.formatter}.exs", "{apps,config,lib,test}/**/*.{ex,exs}"],
    formatter: {Recode.Formatter, []},
    tasks: [
      {Recode.Task.AliasExpansion, []},
      {Recode.Task.AliasOrder, []},
      {Recode.Task.Dbg, [autocorrect: false]},
      {Recode.Task.EnforceLineLength, [active: false]},
      {Recode.Task.FilterCount, []},
      {Recode.Task.PipeFunOne, []},
      {Recode.Task.SinglePipe, []},
      {Recode.Task.Specs, [exclude: "test/**/*.{ex,exs}", config: [only: :visible]]},
      {Recode.Task.TestFileExt, []},
      {Recode.Task.UnusedVariable, [active: false]}
    ]
  ]

  @doc """
  Returns the default configuration.
  """
  @spec default() :: config()
  def default, do: @config_default

  @doc """
  Returns the given config as a formatted string with comments.
  """
  @spec to_string(config()) :: String.t()
  def to_string(config \\ default()) do
    Keyword.validate!(config, @config_keys)

    template = """
    [
      version: "<%= @config[:version] %>",
      # Can also be set/reset with `--autocorrect`/`--no-autocorrect`.
      autocorrect: <%= @config[:autocorrect] %>,
      # With "--dry" no changes will be written to the files.
      # Can also be set/reset with `--dry`/`--no-dry`.
      # If dry is true then verbose is also active.
      dry: <%= @config[:dry] %>,
      # Can also be set/reset with `--verbose`/`--no-verbose`.
      verbose: <%= @config[:verbose] %>,
      # Can be overwriten by calling `mix recode "lib/**/*.ex"`.
      inputs: <%= inspect @config[:inputs] %>,
      formatter: <%= inspect @config[:formatter] %>,
      tasks: [
        # Tasks could be added by a tuple of the tasks module name and an options
        # keyword list. A task can be deactived by `active: false`. The execution of
        # a deactivated task can be forced by calling `mix recode --task ModuleName`.
        <%= for task <- @config[:tasks] do %><%= inspect task %>,
        <% end %>
      ]
    ]
    """

    template
    |> EEx.eval_string(assigns: [config: config])
    |> Code.format_string!()
    |> IO.iodata_to_binary()
  end

  @spec read(Path.t() | opts) :: {:ok, config()} | {:error, :not_found} when opts: keyword()
  def read(opts \\ [])

  def read(path) when is_binary(path) do
    case File.exists?(path) do
      true ->
        config =
          path
          |> Code.eval_file()
          |> elem(0)
          |> default(:tasks)
          |> update(:inputs)

        {:ok, config}

      false ->
        {:error, :not_found}
    end
  end

  def read(opts) when is_list(opts) do
    opts
    |> Keyword.get(:config, @config_filename)
    |> read()
  end

  def validate(config) do
    with :ok <- validate(config, :version) do
      validate(config, :tasks)
    end
  end

  def validate(config, :version) do
    cmp =
      config
      |> Keyword.get(:version, @config_min_version)
      |> Version.compare(@config_min_version)

    if cmp == :lt do
      {:error, :out_of_date}
    else
      :ok
    end
  end

  def validate(config, :tasks) do
    if Keyword.has_key?(config, :tasks), do: :ok, else: {:error, :no_tasks}
  end

  defp default(config, :tasks) do
    Keyword.update!(config, :tasks, fn tasks -> [{Format, []} | tasks] end)
  end

  defp update(config, :inputs) do
    Keyword.update(config, :inputs, [], fn inputs ->
      inputs |> List.wrap() |> Enum.map(fn input -> GlobEx.compile!(input) end)
    end)
  end
end
