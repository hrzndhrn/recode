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

  @impl true
  def features(_opts) do
    [extensions: [".ex", ".exs"]]
  end

  @impl true
  def format(content, opts) do
    if seen?(opts[:file]) do
      content
    else
      {:ok, config} = Config.read()

      Recode.Runner.run(content, config, opts[:file])
    end
  end

  defp seen?(file) do
    table = table()

    case :ets.lookup(table, file) do
      [] ->
        :ets.insert(table, {file})
        false

      _seen ->
        true
    end
  end

  @table :recode_formatter_plugin
  defp table do
    case :ets.whereis(@table) do
      :undefined -> :ets.new(@table, [:set, :public, :named_table])
      _ref -> @table
    end
  end
end
