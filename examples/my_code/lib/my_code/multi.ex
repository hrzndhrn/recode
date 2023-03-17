defmodule MyCode.Multi do
  @moduledoc false

  import MyCode.Fun

  def double(x), do: x + x

  def pipe(x) do
    x |> double() |> double()
  end

  def single(x) do
    double(x)
  end

  def without_parens(x) do
    noop x
  end
end
