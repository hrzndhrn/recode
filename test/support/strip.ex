defmodule Strip do
  # def strip_meta(value, opts \\ [])

  # def strip_meta(struct, opts) when is_struct(struct) do
  #   IO.inspect("strip_meta struct")
  #   # raise "uups"
  #   struct
  #   |> Map.from_struct()
  #   |> Enum.into(%{}, fn value -> strip_meta(value, opts) end)
  # end

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
end
