defmodule Recode.FormatterPlugin.Config do
  @moduledoc false
end

defmodule Recode.FormatterPlugin do
  @moduledoc """
  Defines Recode formatter plugin for `mix format`.

  Since Elixir 1.13, it is possible to define custom formatter plugins. This
  plugin allows you to run Recode autocorrecting tasks together when executing
  `mix format`.

  To use this formatter, simply add `Recode.FormatterPlugin` to your
  `.formatter.exs` plugins:

  ```
    [
      inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
      plugins: [Recode.FormatterPlugin]
    ]
  ```

  By default it uses the `.recode.exs` configuration file.

  If your project does not have a `.recode.exs` configuration file or if you
  want to overwrite the configuration, you can pass the configuration using the
  `recode` option:

  ```
    [
      inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
      plugins: [Recode.FormatterPlugin],
      recode: [
        tasks: [
          {Recode.Task.AliasExpansion, []},
          {Recode.Task.EnforceLineLength, []},
          {Recode.Task.SinglePipe, []}
        ]
      ]
    ]
  ```
  """

  @behaviour Mix.Tasks.Format

  alias Recode.Config
  alias Recode.Runner

  @table :recode_formatter_plugin

  @impl true
  def features(_opts) do
    [extensions: [".ex", ".exs"]]
  end

  @impl true
  def format(content, formatter_opts) do
    _ref = init(formatter_opts)

    file = formatter_opts |> Keyword.get(:file, "source.ex") |> Path.relative_to_cwd()

    formatter_opts =
      Keyword.update(formatter_opts, :plugins, [], fn plugins ->
        Enum.reject(plugins, fn plugin -> plugin == Recode.FormatterPlugin end)
      end)

    config = Keyword.put(config(), :dot_formatter_opts, Keyword.delete(formatter_opts, :recode))

    Runner.run(content, config, file)
  end

  defp config do
    case :ets.lookup(@table, :config) do
      [{:config, config}] -> config
      [] -> config()
    end
  rescue
    _error -> config()
  end

  defp init(opts) do
    if new_table() == :ok do
      config = init_config(opts[:recode])
      :ets.insert(@table, {:config, config})
    end

    :ok
  end

  defp new_table do
    _ref = :ets.new(@table, [:set, :public, :named_table])
    :ok
  rescue
    _error -> :error
  end

  @config_error """
  No configuration for `Recode.FormatterPlugin` found. Run \
  `mix recode.get.config` to create a config file or add config in \
  `.formatter.exs` under the key `:recode`.
  """
  defp init_config(nil) do
    case Config.read() do
      {:error, :not_found} -> Mix.raise(@config_error)
      {:ok, config} -> init_config(config)
    end
  end

  defp init_config(recode) do
    recode
    |> Keyword.merge(
      dry: false,
      verbose: false,
      autocorrect: true,
      check: false
    )
    |> validate_config!()
  end

  defp validate_config!(config) do
    case Config.validate(config) do
      :ok ->
        config

      {:error, :out_of_date} ->
        Mix.raise("The config is out of date. Run `mix recode.update.config` to update.")

      {:error, :no_tasks} ->
        Mix.raise("No `:tasks` key found in configuration.")
    end
  end
end
