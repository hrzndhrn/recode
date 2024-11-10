defmodule Recode.CLIFormatter do
  @moduledoc false

  use GenServer

  import Recode.Formatter

  alias IO.ANSI
  alias Rewrite.Source

  @theme %{
    gainsboro: ANSI.color(4, 4, 4),
    orange: ANSI.color(5, 3, 0),
    aquamarine: ANSI.color(2, 5, 4),
    gray: ANSI.color(59),
    info: :gainsboro,
    file: :green,
    issue: :cyan,
    warn: :orange,
    debug: :cyan,
    ok: :green,
    updated: :green,
    correctable: :aquamarine,
    error: :red,
    del: :red,
    del_background: :red_background,
    ins: :green,
    ins_background: :green_background,
    skip: :yellow,
    separator: :gray,
    blank: " "
  }

  @diff_format [
    colors: [
      del: [text: :del, space: :del_background],
      ins: [text: :ins, space: :ins_background],
      skip: [text: :skip],
      separator: [text: :separator]
    ]
  ]

  @default_config [debug: false, verbose: false]

  def init(config) do
    coloring =
      case Keyword.get(config, :color, true) do
        false -> [emit: false]
        true -> [emit: true, theme: @theme]
        theme -> [emit: true, theme: theme]
      end

    config =
      config
      |> Keyword.take([:debug, :verbose])
      |> merge_into(@default_config)
      |> Keyword.merge(coloring)
      |> Keyword.put(:colorizer, Escape.colorizer(coloring))

    {:ok, config}
  end

  defp merge_into(keywords1, keywords2), do: Keyword.merge(keywords2, keywords1)

  def handle_cast({:prepared, %Rewrite{} = project, time}, config) when is_integer(time) do
    case Enum.count(project.sources) do
      0 ->
        :ok

      1 ->
        Escape.puts([:info, "Read 1 file"], config)

      count ->
        Escape.puts([:info, "Read #{count} files in #{format_time(time)}s"], config)
    end

    {:noreply, config}
  end

  def handle_cast({:finished, %Rewrite{} = project, time}, config) when is_integer(time) do
    unless Enum.empty?(project) and Enum.empty?(project.excluded) do
      Escape.puts([:info, "Finished in #{format_time(time)}s."], config)
    end

    {:noreply, config}
  end

  def handle_cast({:task_started, %Source{} = source, task}, config) when is_atom(task) do
    if config[:debug] do
      Escape.puts([:debug, "Start #{task} with #{source.path}."], config)
    end

    {:noreply, config}
  end

  def handle_cast({:task_finished, %Source{} = source, task, time}, config) when is_atom(task) do
    if config[:debug] do
      Escape.puts([:debug, "Finished #{task} with #{source.path} [#{time}μs]."], config)
    else
      cond do
        issue?(source, task) -> Escape.write([:warn, "!"], config)
        changed?(source, task) -> Escape.write([:updated, "!"], config)
        true -> Escape.write([:ok, "."], config)
      end
    end

    config =
      Keyword.update(config, :times, [{task, source.path, time}], fn times ->
        [{task, source.path, time} | times]
      end)

    {:noreply, config}
  end

  def handle_cast({:tasks_finished, %Rewrite{} = project, time}, config) do
    unless Enum.empty?(project) and Enum.empty?(project.excluded) do
      Escape.puts("")
      stats = format_results(project, config)
      :ok = format_tasks_stats(config, time)
      :ok = format_slowest_tasks(config[:slowest_tasks], config)
      :ok = format_stats(project, stats, config)
      :ok = format_ok(stats, config)
    end

    {:noreply, config}
  end

  defp format_tasks_stats(config, time) do
    executions = length(Keyword.get(config, :times, []))

    Escape.puts([:info, "Executed #{executions} tasks in #{format_time(time)}s."], config)
  end

  defp format_results(project, config) do
    verbose = Keyword.fetch!(config, :verbose)

    stats = %{extname_count: %{}, issues: 0, updated: 0, created: 0, moved: 0}

    project
    |> Rewrite.sources()
    |> Enum.reduce(stats, fn source, stats ->
      opts = [
        issues?: Source.has_issues?(source, :all),
        code_updated?: Source.updated?(source, :content),
        path_updated?: Source.updated?(source, :path),
        created?: Source.from?(source, :string)
      ]

      format_result(source, verbose, opts, config)

      stats
      |> stats_count(:issues, opts[:issues?], Enum.count(source.issues))
      |> stats_count(:updated, opts[:code_updated?])
      |> stats_count(:moved, opts[:path_updated?])
      |> stats_count(:created, opts[:created?])
      |> extname_count(source)
    end)
  end

  defp format_stats(project, stats, config) do
    file_stats =
      stats
      |> Map.get(:extname_count)
      |> Enum.map_join(", ", fn {extname, count} -> "#{extname}: #{count}" end)

    file_stats = if file_stats == "", do: "", else: "(#{file_stats})"

    excluded =
      if Enum.empty?(project.excluded),
        do: "",
        else: ", excluded: #{length(project.excluded)}"

    processed = "Files processed: #{Enum.count(project)} "

    Escape.puts([:info, processed, file_stats, excluded], config)

    _stats =
      stats
      |> format_stat(:created, :info, ["Created # file", "Created # files"], config)
      |> format_stat(:moved, :info, ["Moved # file", "Moved # files"], config)
      |> format_stat(:updated, :info, ["Updated # file", "Updated # files"], config)

    :ok
  end

  defp format_ok(%{issues: issues}, config) do
    output =
      case issues do
        0 -> [:ok, :reverse, :blank, "Everything ok", :blank, :reverse_off]
        1 -> [:warn, :reverse, :blank, "Found 1 issue", :blank, :reverse_off]
        count -> [:warn, :reverse, :blank, "Found #{count} issues", :blank, :reverse_off]
      end

    Escape.puts(output, config)
  end

  defp format_stat(stats, key, kind, templates, config) do
    output =
      case Map.fetch!(stats, key) do
        0 -> []
        1 -> [kind, templates |> Enum.at(0) |> String.replace("#", "1"), "\n"]
        count -> [kind, templates |> Enum.at(1) |> String.replace("#", "#{count}"), "\n"]
      end

    Escape.write(output, config)

    stats
  end

  defp stats_count(stats, key, count?, add \\ 1)

  defp stats_count(stats, key, true, add) do
    Map.update!(stats, key, fn value -> value + add end)
  end

  defp stats_count(stats, _key, false, _add), do: stats

  defp extname_count(stats, source) do
    Map.update!(stats, :extname_count, fn extname_count ->
      extname = Path.extname(source.path)
      Map.update(extname_count, extname, 1, fn count -> count + 1 end)
    end)
  end

  defp format_result(source, verbose, opts, config) do
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
    |> format_code_update(source, code_updated?, config)
    |> format_issues(source, issues?, verbose)
    |> then(fn
      [] -> []
      content -> Enum.concat(content, ["\n"])
    end)
    |> Escape.write(config)
  end

  defp format_file(output, _source, false), do: output

  defp format_file(output, source, true) do
    Enum.concat(output, [
      :file,
      :reverse,
      :blank,
      "File: #{source.path || "no file"}",
      :blank,
      :reverse_off,
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

  defp format_code_update(output, _source, false, _config), do: output

  defp format_code_update(output, source, true, config) do
    Enum.concat([
      output,
      changed_by(source),
      [ANSI.reset()],
      [
        source
        |> Source.diff(
          format: @diff_format,
          colorizer: config[:colorizer]
        )
        |> IO.iodata_to_binary()
      ]
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
    [:error, "Execution of the #{inspect(meta[:task])} task failed with error:\n#{message}\n"]
  end

  defp format_issue(%{reporter: Recode.Runner, meta: meta}, _version, _actual, false) do
    [:error, "Execution of the #{inspect(meta[:task])} task failed.\n"]
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

  defp format_slowest_tasks(nil, _config), do: :ok

  defp format_slowest_tasks(amount, config) do
    slowest_tasks =
      config
      |> Keyword.get(:times, [])
      |> Enum.reduce(%{}, fn {task, _path, time}, acc ->
        Map.update(acc, task, {1, time}, fn {calls, duration} -> {calls + 1, duration + time} end)
      end)
      |> Enum.into([], fn {task, {calls, time}} -> {task, calls, round(time / calls)} end)
      |> Enum.sort_by(&elem(&1, 2), :desc)
      |> Enum.take(amount)
      |> Enum.with_index(1)
      |> Enum.map(fn {{task, calls, time}, index} ->
        """
        #{index} - \
        task: #{inspect(task)}, \
        calls: #{calls}, \
        avg: #{format_time(time, :millisecond)}ms
        """
      end)

    Escape.puts([:info, "\nSlowest tasks:\n", slowest_tasks], config)
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
