defmodule Recode.IO do
  @moduledoc """
  TODO: @moduledoc
  """

  @colors %{
    file: :green,
    info: :color251,
    line_num: :color244,
    equal: :color244,
    del: :red,
    ins: :green
  }

  def puts(chardata) do
    chardata
    |> Enum.map(&colors/1)
    |> Bunt.puts
  end

  defp colors(data) when is_atom(data), do: Map.get(@colors, data, data)

  defp colors(data), do: data
end
