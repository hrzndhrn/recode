defmodule MyCode.Multi do
  @moduledoc false

  import MyCode.Fun

  def double(x), do: x + x

  def pipe(x) do
    x |> double |> double() |> dbg()
  end

  def single(x) do
    x |> double()
  end

  def without_parens(x) do
    noop x
  end

  def my_count(list) do
    list
    |> Enum.filter(fn x -> rem(x, 2) == 0 end)
    |> Enum.count()
    |> IO.inspect()
  end
end
