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

  @persistent_term_key {__MODULE__, :config}

  @impl true
  def features(_opts) do
    [extensions: [".ex", ".exs"]]
  end

  @impl true
  def format(content, formatter_opts) do
    file = formatter_opts |> Keyword.get(:file, "source.ex") |> Path.relative_to_cwd()

    formatter_opts =
      Keyword.update(formatter_opts, :plugins, [], fn plugins ->
        Enum.reject(plugins, fn plugin -> plugin == Recode.FormatterPlugin end)
      end)

    config =
      formatter_opts
      |> config()
      |> Keyword.put(:dot_formatter_opts, Keyword.delete(formatter_opts, :recode))

    Runner.run(content, config, file)
  end

  defp config(opts) do
    with nil <- :persistent_term.get(@persistent_term_key, nil) do
      config = init_config(opts[:recode])
      :ok = :persistent_term.put(@persistent_term_key, config)
      config
    end
  end

  @config_error """
  No configuration for `Recode.FormatterPlugin` found. Run \
  `mix recode.gen.config` to create a config file or add config in \
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
