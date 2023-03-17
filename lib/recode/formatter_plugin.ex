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

  If your project does not have a `.recode.exs` configuration file, you can pass
  the configuration using the `recode` option:

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

  @table :recode_formatter_plugin

  @impl true
  def features(_opts) do
    # A little misappropriated as `&init/0/1`
    init()

    [extensions: [".ex", ".exs"]]
  end

  @impl true
  def format(content, opts) do
    if seen?(opts[:file]) do
      content
    else
      Recode.Runner.run(content, config(opts[:recode]), opts[:file])
    end
  end

  defp seen?(file) do
    case :ets.lookup(@table, file) do
      [] ->
        :ets.insert(@table, {file})
        false

      _seen ->
        true
    end
  end

  defp config(nil) do
    case {:ets.lookup(@table, :config), self()} do
      {[], pid} ->
        :ets.insert(@table, {:config, {:loading, pid}})
        config(nil)

      {[{:config, {:loading, pid}}], pid} ->
        config = read_config()
        :ets.insert(@table, {:config, config})
        config

      {[{:config, {:loading, _loader}}], _pid} ->
        config(nil)

      {[{:config, config}], _pid} ->
        config
    end
  end

  defp read_config do
    {:ok, config} = Config.read()
    config
  end

  defp init do
    with :undefined <- :ets.whereis(@table) do
      :ets.new(@table, [:set, :public, :named_table])
    end
  end
end
