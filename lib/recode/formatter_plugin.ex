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
  alias Recode.Task
  alias Rewrite.Project
  alias Rewrite.Source

  @impl true
  def features(_opts) do
    [extensions: [".ex", ".exs"]]
  end

  @impl true
  def format(contents, opts) do
    file = Keyword.fetch!(opts, :file)
    config = Keyword.get(opts, :recode, [])
    project = project_from_string(contents, file)

    config
    |> merge_project_config()
    |> force_formatter_config(project)
    |> Recode.Runner.run()
    |> Project.source!(file)
    |> Source.code()
  end

  defp project_from_string(string, file) do
    string
    |> Source.from_string(file)
    |> List.wrap()
    |> Project.from_sources()
  end

  defp merge_project_config(config) do
    case Config.read(config) do
      {:ok, merged_config} -> merged_config
      {:error, :not_found} -> config
    end
  end

  defp force_formatter_config(config, project) do
    config
    |> Keyword.put(:project, project)
    |> Keyword.put(:autocorrect, true)
    |> Keyword.put(:dry, true)
    |> Keyword.put(:verbose, false)
    |> Keyword.delete(:formatter)
    |> Keyword.update(:tasks, [], &force_default_formatter_task/1)
  end

  defp force_default_formatter_task(tasks) do
    default_formatter = {Task.Format, config: [force_default_formatter: true]}

    tasks
    |> Enum.reject(&match?({Task.Format, _}, &1))
    |> Enum.concat([default_formatter])
  end
end
