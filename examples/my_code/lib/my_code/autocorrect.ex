defmodule MyCode.Autocorrect do
  def double(x), do: x + x

  def pipe(x) do
    x |> double |> double()
  end

  def single_pipe(x) do
    x |> double
  end
end
