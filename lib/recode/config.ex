defmodule Recode.Config do
  @moduledoc """
  Functions to read and merge the `Recode` configuration.
  """

  @type config :: keyword()

  @config_filename ".recode.exs"

  @config_version "0.8.0"

  # The minimum version of the config to run recode. This version marks the last
  # breaking change for handle the config.
  @config_min_version "0.8.0"

  @config_keys [
    :autocorrect,
    :color,
    :dry,
    :formatters,
    :inputs,
    :manifest,
    :tasks,
    :verbose,
    :version
  ]

  # The default configuration used by mix tasks recode.gen.config and
  # recode.update.config.
  @config_default [
    version: @config_version,
    autocorrect: true,
    dry: false,
    color: true,
    verbose: false,
    inputs: :formatter,
    formatters: [Recode.CLIFormatter],
    manifest: true,
    tasks: [
      {Recode.Task.AliasExpansion, []},
      {Recode.Task.AliasOrder, []},
      {Recode.Task.Dbg, [autocorrect: false]},
      {Recode.Task.EnforceLineLength, [active: false]},
      {Recode.Task.FilterCount, []},
      {Recode.Task.IOInspect, [autocorrect: false]},
      {Recode.Task.LocalsWithoutParens, []},
      {Recode.Task.Moduledoc, []},
      {Recode.Task.Nesting, []},
      {Recode.Task.PipeFunOne, []},
      {Recode.Task.SinglePipe, []},
      {Recode.Task.Specs, [exclude: ["test/**/*.{ex,exs}", "mix.exs"], config: [only: :visible]]},
      {Recode.Task.TagFIXME, exit_code: 2},
      {Recode.Task.TagTODO, exit_code: 4},
      {Recode.Task.TestFile, []},
      {Recode.Task.UnnecessaryIfUnless, []},
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
    config = Keyword.validate!(config, @config_keys)

    template = """
    [
      version: "<%= @config[:version] %>",
      # Can also be set/reset with `--autocorrect`/`--no-autocorrect`.
      autocorrect: <%= @config[:autocorrect] %>,
      # With "--dry" no changes will be written to the files.
      # Can also be set/reset with `--dry`/`--no-dry`.
      # If dry is true then verbose is also active.
      dry: <%= @config[:dry] %>,
      # Enables or disables color in the output.
      color: <%= @config[:color] %>,
      # Can also be set/reset with `--verbose`/`--no-verbose`.
      verbose: <%= @config[:verbose] %>,
      # Inputs can be a path, glob expression or list of paths and glob expressions.
      # With the atom :formatter the inputs from .formatter.exs are
      # used. also allowed in the list mentioned above.
      # Can be overwritten by calling `mix recode "lib/**/*.ex"`.
      inputs: <%= inspect @config[:inputs] %>,
      formatters: <%= inspect @config[:formatters] %>,
      # Can also be set/reset with `--manifest`/`--no-manifest`.
      manifest: <%= inspect @config[:manifest] %>,
      tasks: [
        # Tasks could be added by a tuple of the tasks module name and an options
        # keyword list. A task can be deactivated by `active: false`. The execution of
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

  @doc """
  Merges two configs into one.

  The merge will do a deep merge. The merge takes the version from the `right`
  config.

  ## Examples

      iex> new = [version: "0.0.2", verbose: false, autocorrect: true]
      ...> old = [version: "0.0.1", verbose: true]
      iex> Recode.Config.merge(new ,old) |> Enum.sort()
      [autocorrect: true, verbose: true, version: "0.0.2"]
  """
  @spec merge(config, config) :: config
  def merge(left \\ default(), right) do
    Keyword.merge(left, right, fn
      :version, version, _ -> version
      :tasks, left, right -> merge_tasks(left, right)
      _, _, value -> value
    end)
  end

  defp merge_tasks(left, right) do
    left
    |> Keyword.merge(right, fn
      _key, left, [] -> left
      _key, left, right -> merge_task_config(left, right)
    end)
    |> Enum.sort()
  end

  defp merge_task_config(left, right) do
    Keyword.merge(left, right, fn
      :config, left, right -> left |> Keyword.merge(right) |> Enum.sort()
      _key, _left, right -> right
    end)
  end

  @doc """
  Deletes the given `tasks` from the `config`.
  """
  @spec delete_tasks(config, [module()]) :: config
  def delete_tasks(config, tasks) do
    Keyword.update(config, :tasks, [], fn current_tasks ->
      Keyword.drop(current_tasks, tasks)
    end)
  end

  @doc """
  Reads the `Recode` cofiguration from the given `path`.
  """
  @spec read(Path.t()) :: {:ok, config()} | {:error, :not_found}
  def read(path \\ @config_filename) when is_binary(path) do
    case File.exists?(path) do
      true ->
        config =
          path
          |> Code.eval_file()
          |> elem(0)
          |> Keyword.put_new(:manifest, true)

        {:ok, config}

      false ->
        {:error, :not_found}
    end
  end

  @doc """
  Validates the config version and tasks.
  """
  @spec validate(config()) :: :ok | {:error, :out_of_date | :no_tasks}
  def validate(config) do
    with :ok <- validate_version(config) do
      validate_tasks(config)
    end
  end

  defp validate_version(config) do
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

  defp validate_tasks(config) do
    if Keyword.has_key?(config, :tasks), do: :ok, else: {:error, :no_tasks}
  end
end
