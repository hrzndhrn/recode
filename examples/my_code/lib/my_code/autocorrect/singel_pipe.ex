defmodule MyCode.Autocorrect.SinglePipe do
  def double(x), do: x + x

  def single_pipe(x) do
    x |> double()
  end

  def reverse(a), do: a |> Enum.reverse()
end
