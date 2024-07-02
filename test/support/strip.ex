defmodule Strip do
  @moduledoc false

  def strip_meta(quoted, opts) when not is_struct(quoted) do
    Macro.prewalk(quoted, fn quoted -> do_strip_meta(quoted, opts) end)
  end

  defp do_strip_meta({form, meta, args}, opts) do
    cond do
      Keyword.has_key?(opts, :take) -> {form, Keyword.take(meta, opts[:take]), args}
      Keyword.has_key?(opts, :drop) -> {form, Keyword.drop(meta, opts[:drop]), args}
      true -> {form, [], args}
    end
  end

  defp do_strip_meta(quoted, _opts), do: quoted

  def strip_esc_seq(string) do
    string
    |> String.replace(~r/\e[^m]+m/, "")
    |> String.split("\n")
    |> Enum.map_join("\n", fn string ->
      ~r/^\s(\w.*)/
      |> Regex.replace(string, "\\1")
      |> String.trim_trailing()
    end)
    |> String.trim_leading()
  end
end
