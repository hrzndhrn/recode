defmodule Recode.Formatter do
  @moduledoc """
  The default formatter and the formatter bebaviour.
  """

  import IO.ANSI, only: [reverse: 0, reverse_off: 0]
  import Recode.IO

  alias Recode.Project
  alias Recode.Source

  @callback format(Project.t(), opts :: keyword(), config :: keyword()) :: :ok

  def format(%Project{} = project, opts, config) do
    verbose = Keyword.fetch!(config, :verbose)

    project
    |> Project.sources()
    |> Enum.each(fn source -> do_format(source, opts, verbose) end)

    project
  end

  defp do_format(source, opts, verbose) do
    issues? = Source.has_issues?(source, :all)
    updated? = Source.updated?(source) and verbose

    []
    |> format_file(source, opts, issues? or updated?)
    |> format_updates(source, opts, updated?)
    |> format_path_update(source, opts, updated?)
    |> format_code_update(source, opts, updated?)
    |> format_issues(source, opts, issues?)
    |> newline(issues? or updated?)
    |> write()
  end

  defp newline(output, false), do: output

  defp newline(output, true), do: Enum.concat(output, ["\n"])

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
    case Source.updated?(source, :path) do
      true ->
        Enum.concat([
          output,
          changed_by(source),
          ["Moved from: #{Source.path(source, 1)}"]
        ])

      false ->
        output
    end
  end

  defp format_code_update(output, _source, _opts, false), do: output

  defp format_code_update(output, source, _opts, true) do
    case Source.updated?(source, :code) do
      true ->
        Enum.concat([
          output,
          changed_by(source),
          diff(Source.code(source), Source.code(source, 1))
        ])

      false ->
        output
    end
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

  defp diff(code, code), do: []

  defp diff(new, old) do
    new = String.split(new, "\n")
    old = String.split(old, "\n")

    old
    |> List.myers_difference(new)
    |> diff_to_iodata()
  end

  defp diff_to_iodata(diff, line_num \\ 0, iodata \\ [])

  defp diff_to_iodata([], _line_num, iodata), do: iodata |> Enum.reverse() |> List.flatten()

  defp diff_to_iodata([{:eq, lines} | diff], 0, iodata) do
    {skip, lines} = Enum.split(lines, -2)

    diff_to_iodata([{:equal, lines} | diff], length(skip), iodata)
  end

  defp diff_to_iodata([{:eq, lines}], line_num, iodata) do
    io_lines = lines |> Enum.take(2) |> code_lines(line_num, :equal)
    line_num = line_num + length(lines)

    diff_to_iodata([], line_num, [io_lines | iodata])
  end

  defp diff_to_iodata([{:eq, lines} | diff], line_num, iodata) do
    case length(lines) > 5 do
      true ->
        io_lines = lines |> Enum.take(2) |> code_lines(line_num, :equal)
        line_num = line_num + length(lines)
        diff_to_iodata(diff, line_num, [line_num(:skip), io_lines | iodata])

      false ->
        diff_to_iodata([{:equal, lines} | diff], line_num, iodata)
    end
  end

  defp diff_to_iodata([{kind, lines} | diff], line_num, iodata) do
    io_lines = code_lines(lines, line_num, kind)

    line_num =
      case kind do
        :del -> line_num
        _kind -> line_num + length(lines)
      end

    diff_to_iodata(diff, line_num, [io_lines | iodata])
  end

  defp code_lines(lines, line_num, kind, iodata \\ [])

  defp code_lines([], _line_num, _kine, iodata), do: Enum.reverse(iodata)

  defp code_lines([line | lines], line_num, kind, iodata) do
    line_num = line_num + 1
    line = [:line_num, "#{line_num(line_num, kind)}", kind, "#{line}\n"]
    code_lines(lines, line_num, kind, [line | iodata])
  end

  defp line_num(:skip), do: [:line_num, "... |\n"]

  defp line_num(num, kind) do
    kind =
      case kind do
        :del -> " - "
        :ins -> " + "
        _else -> "   "
      end

    String.pad_leading("#{num}#{kind}|", 7, "0")
  end
end
