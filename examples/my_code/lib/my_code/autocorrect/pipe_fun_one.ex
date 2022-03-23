defmodule MyCode.Autocorrect.PipeFunOne do
  def double(x), do: x + x

  def pipe(x) do
    x |> double |> double()
  end
end
