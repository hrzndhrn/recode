defmodule MyCode.PipeFunOne do
  @moduledoc false

  def double(x), do: x + x

  def pipe(x) do
    x |> double() |> double()
  end
end
