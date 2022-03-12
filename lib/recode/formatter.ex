defmodule Recode.Formatter do
  @moduledoc """
  The default formatter and the formatter bebaviour.
  """

  import Recode.IO

  alias Recode.Project
  alias Recode.Source

  @callback format(Project.t(), opts :: keyword(), config :: keyword()) :: :ok

  def format(%Project{} = project, opts, _config) do
    project
    |> Project.sources()
    |> Enum.each(fn source -> format(source, opts) end)

    project
  end

  defp format(source, _opts) do
    puts([
      :file,
      "File: #{source.path || "no file"}",
      :info,
      " Updates: #{Source.updates(source)}"
    ])

    if Source.updated?(source) do
      changed_by(source)
      diff(Source.code(source), Source.code(source, 0))
    end
  end

  defp changed_by(%Source{versions: versions}) do
    by =
      versions
      |> Enum.filter(fn {key, _by, _value} -> key == :code end)
      |> Enum.map(fn {_key, by, _value} -> Macro.to_string(by) end)

    puts([:info, "Changed by: " <> Enum.join(by, ", ")])
  end

  defp diff(code, code), do: :ok

  defp diff(new, old) do
    # String.myers_difference(new, old)
    new = String.split(new, "\n")
    old = String.split(old, "\n")

    old
    |> List.myers_difference(new)
    |> diff_to_iodata()
    |> puts()
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
    line = [:line_num, "#{line_num(line_num)}", kind, "#{line}\n"]
    code_lines(lines, line_num, kind, [line | iodata])
  end

  defp line_num(:skip), do: [:line_num, "...|\n"]

  defp line_num(num) do
    String.pad_leading("#{num}|", 4, "0")
  end
end
