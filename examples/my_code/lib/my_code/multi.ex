defmodule MyCode.Multi do
  def double(x), do: x + x

  def pipe(x) do
    x |> double |> double()
  end

  def single(x) do
    x |> double()
  end
end
