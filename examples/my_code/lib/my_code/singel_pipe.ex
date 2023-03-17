defmodule MyCode.SinglePipe do
  @moduledoc false

  def double(x), do: x + x

  def single_pipe(x) do
    double(x)
  end

  def reverse(a), do: Enum.reverse(a)
end
