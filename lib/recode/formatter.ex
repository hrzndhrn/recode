defmodule Recode.Formatter do
  @moduledoc """
  The default formatter and the formatter bebaviour.
  """

  import Recode.IO

  alias Rewrite.Project
  alias Rewrite.Source

  @callback format(
              type :: :project | :results | :tasks_ready,
              {Project.t(), config :: keyword()},
              opts :: keyword()
            ) :: any()

  @callback format(
              type :: :task,
              {Project.t(), config :: keyword()},
              {Source.t(), module, keyword()},
              opts :: keyword()
            ) :: any()

  @spec format(
          type :: :project | :results | :tasks_ready,
          {Project.t(), config :: keyword()},
          opts :: keyword()
        ) :: any()
  def format(:results, {%Project{} = project, config}, opts) do
    verbose = Keyword.fetch!(config, :verbose)

    project
    |> Project.sources()
    |> Enum.each(fn source -> do_format(source, opts, verbose) end)
  end

  def format(:tasks_ready, {%Project{} = project, _config}, _opts) do
    case Project.sources(project) do
      [] -> :ok
      [_ | _] -> write("\n")
    end
  end

  def format(:project, {%Project{} = project, _config}, _opts) do
    case counts(project) do
      {0, 0} ->
        :ok

      {sources, scripts} ->
        puts([:info, "Found #{sources} files, including #{scripts} scripts."])
    end
  end

  @spec format(
          type :: :task,
          {Project.t(), config :: keyword()},
          {Source.t(), module, keyword()},
          opts :: keyword()
        ) :: any()
  def format(:task, {_project, _config}, {_source, _task_module, _task_opts}, _opts) do
    write(".")
  end

  defp counts(project) do
    {
      Project.count(project, :sources),
      Project.count(project, :scripts)
    }
  end

  defp do_format(source, opts, verbose) do
    issues? = Source.has_issues?(source, :all)
    code_updated? = Source.updated?(source, :code) and verbose
    path_updated? = Source.updated?(source, :path) and verbose
    updated? = code_updated? or path_updated?

    []
    |> format_file(source, opts, issues? or updated?)
    |> format_updates(source, opts, updated?)
    |> format_path_update(source, opts, path_updated?)
    |> format_code_update(source, opts, code_updated?)
    |> format_issues(source, opts, issues?)
    |> newline(issues? or updated?)
    |> write()
  end

  defp newline(output), do: Enum.concat(output, ["\n"])

  defp newline(output, false), do: output

  defp newline(output, true), do: newline(output)

  defp format_updates(output, _source, _opts, false), do: output

  defp format_updates(output, source, _opts, true) do
    Enum.concat(output, [:info, "Updates: #{Source.version(source) - 1}\n"])
  end

  defp format_file(output, _source, _opts, false), do: output

  defp format_file(output, source, _opts, true) do
    Enum.concat(output, [
      :file,
      reverse(),
      " File: #{source.path || "no file"} ",
      reverse_off(),
      "\n"
    ])
  end

  defp format_path_update(output, _source, _opts, false), do: output

  defp format_path_update(output, source, _opts, true) do
    Enum.concat([
      output,
      changed_by(source),
      ["Moved from: #{Source.path(source, 1)}"]
    ])
  end

  defp format_code_update(output, _source, _opts, false), do: output

  defp format_code_update(output, source, _opts, true) do
    Enum.concat([
      output,
      changed_by(source),
      [Source.diff(source, iodata: true) |> IO.iodata_to_binary()]
    ])
  end

  defp format_issues(output, _source, _opts, false), do: output

  defp format_issues(output, source, _opts, true) do
    actual = Source.version(source)

    issues =
      source
      |> Map.get(:issues)
      |> Enum.sort(&sort_issues/2)
      |> Enum.flat_map(fn {version, issue} ->
        format_issue(issue, version, actual)
      end)

    Enum.concat(output, issues)
  end

  defp sort_issues({_version1, issue1}, {_version2, issue2}) do
    line1 = Map.get(issue1, :line, 0)
    line2 = Map.get(issue2, :line, 0)

    cond do
      line1 == line2 ->
        column1 = Map.get(issue1, :line, 0)
        column2 = Map.get(issue2, :line, 0)

        column1 <= column2

      line1 <= line2 ->
        true

      true ->
        false
    end
  end

  defp format_issue(issue, version, actual) do
    warn =
      case version != actual do
        true ->
          [:warn, "Version #{version}/#{actual} "]

        false ->
          []
      end

    message = [
      :issue,
      "[#{module(issue.reporter)} #{pos(issue)}] ",
      :info,
      "#{issue.message}\n"
    ]

    Enum.concat(warn, message)
  end

  defp pos(issue) do
    line = Map.get(issue, :line) || "-"
    column = Map.get(issue, :column) || "-"

    "#{line}/#{column}"
  end

  defp module(alias), do: alias |> split() |> List.last()

  defp split(module) when is_atom(module), do: module |> to_string() |> split()

  defp split("Elixir." <> name), do: String.split(name, ".")

  defp split(name) when is_binary(name), do: String.split(name, ".")

  defp changed_by(%Source{updates: updates}) do
    by = Enum.map(updates, fn {_key, by, _value} -> module(by) end)

    [:info, ~s|Changed by: #{Enum.join(by, ", ")}\n|]
  end
end
