defmodule Recode.CLIFormatter do
  @moduledoc false

  use GenServer

  import Recode.Formatter
  import Recode.IO

  alias IO.ANSI
  alias Rewrite.Source

  def init(config), do: {:ok, config}

  def handle_cast({:prepared, %Rewrite{} = project, time}, config) when is_integer(time) do
    case Enum.count(project.sources) do
      0 ->
        :ok

      1 ->
        puts([:info, "Found 1 file"])

      count ->
        puts([:info, "Found #{count} files"])
    end

    {:noreply, config}
  end

  def handle_cast({:finished, %Rewrite{} = project, time}, config) when is_integer(time) do
    unless Enum.empty?(project) do
      puts([:info, "Finished in #{format_time(time)}"])
    end

    {:noreply, config}
  end

  def handle_cast({:task_started, %Source{} = source, task}, config) when is_atom(task) do
    if config[:debug] do
      puts([:aqua, "Start #{task} with #{source.path}."])
    end

    {:noreply, config}
  end

  def handle_cast({:task_finished, %Source{} = source, task}, config) when is_atom(task) do
    if config[:debug] do
      puts([:aqua, "Finished #{task} with #{source.path}."])
    else
      cond do
        issue?(source, task) -> write([:warn, "!"])
        changed?(source, task) -> write([:updated, "!"])
        true -> write([:ok, "."])
      end
    end

    {:noreply, config}
  end

  def handle_cast({:tasks_finished, %Rewrite{} = project}, config) do
    unless Enum.empty?(project) do
      puts(["\n"])
      format_results(project, config)
    end

    {:noreply, config}
  end

  defp format_results(project, config) do
    verbose = Keyword.fetch!(config, :verbose)

    stats = %{extname_count: %{}, issues: 0, updated: 0, created: 0, moved: 0}

    stats =
      project
      |> Rewrite.sources()
      |> Enum.reduce(stats, fn source, stats ->
        opts = [
          issues?: Source.has_issues?(source, :all),
          code_updated?: Source.updated?(source, :content),
          path_updated?: Source.updated?(source, :path),
          created?: Source.from?(source, :string)
        ]

        format_result(source, verbose, opts)

        stats
        |> stats_count(:issues, opts[:issues?], Enum.count(source.issues))
        |> stats_count(:updated, opts[:code_updated?])
        |> stats_count(:moved, opts[:path_updated?])
        |> stats_count(:created, opts[:created?])
        |> Map.update!(:extname_count, fn extname_count ->
          extname = Path.extname(source.path)
          Map.update(extname_count, extname, 1, fn count -> count + 1 end)
        end)
      end)

    project
    |> Enum.count()
    |> format_stats(stats)
  end

  defp format_stats(file_count, stats) do
    filte_stats =
      stats
      |> Map.get(:extname_count)
      |> Enum.map_join(", ", fn {extname, count} -> "#{extname}: #{count}" end)

    puts([:info, "Files: #{file_count} ", "(#{filte_stats})"])

    stats
    |> format_stat(:created, :info, ["Created # file", "Created # files"])
    |> format_stat(:moved, :info, ["Moved # file", "Moved # files"])
    |> format_stat(:updated, :info, ["Updated # file", "Updated # files"])
    |> format_ok()
  end

  defp format_ok(%{issues: issues}) do
    case issues do
      0 -> puts([:ok, reverse(), " Everything ok \n", reverse_off()])
      1 -> puts([:warn, reverse(), " Found 1 issue \n", reverse_off()])
      count -> puts([:warn, reverse(), " Found #{count} issues ", reverse_off()])
    end
  end

  defp format_stat(stats, key, kind, templates) do
    case Map.fetch!(stats, key) do
      0 -> :noop
      1 -> puts([kind, templates |> Enum.at(0) |> String.replace("#", "1")])
      count -> puts([kind, templates |> Enum.at(1) |> String.replace("#", "#{count}")])
    end

    stats
  end

  defp stats_count(stats, key, count?, add \\ 1)

  defp stats_count(stats, key, true, add) do
    Map.update!(stats, key, fn value -> value + add end)
  end

  defp stats_count(stats, _key, false, _add), do: stats

  defp format_result(source, verbose, opts) do
    issues? = opts[:issues?]
    code_updated? = opts[:code_updated?] and verbose
    path_updated? = opts[:path_updated?] and verbose
    created? = opts[:created?] and verbose
    updated? = code_updated? or path_updated?

    []
    |> format_file(source, issues? or updated? or created?)
    |> format_created(source, created?)
    |> format_updates(source, updated?)
    |> format_path_update(source, path_updated?)
    |> format_code_update(source, code_updated?)
    |> format_issues(source, issues?, verbose)
    |> then(fn
      [] -> []
      content -> Enum.concat(content, ["\n"])
    end)
    |> write()
  end

  defp format_file(output, _source, false), do: output

  defp format_file(output, source, true) do
    Enum.concat(output, [
      :file,
      reverse(),
      " File: #{source.path || "no file"} ",
      reverse_off(),
      "\n"
    ])
  end

  defp format_created(output, _source, false), do: output

  defp format_created(output, source, true) do
    owner =
      case Source.owner(source) do
        Rewrite -> ""
        module -> ", created by #{inspect(module)}"
      end

    Enum.concat(output, [:info, "New file", "#{owner}\n"])
  end

  defp format_updates(output, _source, false), do: output

  defp format_updates(output, source, true) do
    Enum.concat(output, [:info, "Updates: #{Source.version(source) - 1}\n"])
  end

  defp format_path_update(output, _source, false), do: output

  defp format_path_update(output, source, true) do
    Enum.concat([
      output,
      changed_by(source),
      ["Moved from: #{Source.get(source, :path, 1)}\n"]
    ])
  end

  defp format_code_update(output, _source, false), do: output

  defp format_code_update(output, source, true) do
    Enum.concat([
      output,
      changed_by(source),
      [ANSI.reset()],
      [source |> Source.diff() |> IO.iodata_to_binary()]
    ])
  end

  defp format_issues(output, _source, false, _verbose), do: output

  defp format_issues(output, source, true, verbose) do
    actual = Source.version(source)

    issues =
      source
      |> Map.get(:issues)
      |> Enum.sort(&sort_issues/2)
      |> Enum.flat_map(fn {version, issue} ->
        format_issue(issue, version, actual, verbose)
      end)

    Enum.concat(output, issues)
  end

  defp sort_issues({_version1, issue1}, {_version2, issue2}) do
    line1 = Map.get(issue1, :line, 0)
    line2 = Map.get(issue2, :line, 0)

    cond do
      line1 == line2 ->
        column1 = Map.get(issue1, :column, 0)
        column2 = Map.get(issue2, :column, 0)

        column1 <= column2

      line1 <= line2 ->
        true

      true ->
        false
    end
  end

  defp format_issue(
         %{reporter: Recode.Runner, meta: meta, message: message},
         _version,
         _actual,
         true
       ) do
    [:warn, "Execution of the #{inspect(meta[:task])} task failed with error:\n#{message}\n"]
  end

  defp format_issue(%{reporter: Recode.Runner, meta: meta}, _version, _actual, false) do
    [:warn, "Execution of the #{inspect(meta[:task])} task failed.\n"]
  end

  defp format_issue(issue, version, actual, _verbose) do
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

  defp changed_by(%Source{history: history}) do
    by = Enum.map(history, fn {_key, by, _value} -> module(by) end)

    [:info, ~s|Changed by: #{Enum.join(by, ", ")}\n|]
  end

  defp pos(issue) do
    line = Map.get(issue, :line) || "-"
    column = Map.get(issue, :column) || "-"

    "#{line}/#{column}"
  end

  defp changed?(%Source{history: [{:content, reporter, _content} | _]}, reporter), do: true

  defp changed?(_source, _reporter), do: false

  defp issue?(%Source{issues: [{_version, %{reporter: reporter}} | _]}, reporter), do: true

  defp issue?(_source, _reporter), do: false

  defp module(alias), do: alias |> split() |> List.last()

  defp split(module) when is_atom(module), do: module |> to_string() |> split()

  defp split("Elixir." <> name), do: String.split(name, ".")

  defp split(name) when is_binary(name), do: String.split(name, ".")
end
