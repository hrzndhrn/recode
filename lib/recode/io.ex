defmodule Recode.IO do
  @moduledoc """
  This module provides IO functions and contains the color schema for `Recode`.
  """

  @type color ::
          :del
          | :equal
          | :file
          | :info
          | :ins
          | :issue
          | :line_num
          | :warn

  @colors %{
    del: :red,
    equal: :color244,
    file: :green,
    info: :color251,
    ins: :green,
    issue: :cyan,
    line_num: :color244,
    warn: :orange
  }

  @doc """
  Similar `to write/1`, but adds a newline at the end.
  """
  def puts(chardata) do
    chardata
    |> Enum.map(&colors/1)
    |> Bunt.puts()
  end

  @doc """
  Formats a chardata-like argument by converting named ANSI sequences into
  actual ANSI codes and writes it to `:stdio`.
  """
  def write(chardata) when is_list(chardata) do
    chardata
    |> Enum.map(&colors/1)
    |> Bunt.write()
  end

  def write(string) when is_binary(string), do: IO.write(string)

  defp colors(data) when is_atom(data), do: Map.get(@colors, data, data)

  defp colors(data), do: data

  defdelegate reverse, to: IO.ANSI

  defdelegate reverse_off, to: IO.ANSI
end
