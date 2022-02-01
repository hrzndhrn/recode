defmodule Hello do
  @moduledoc """
  Documentation for `Hello`.
  """

  # `:world |> hello()` will be fixed to `hello(:world)`
  def hello do
    :world |> hello()
  end

  defp hello(atom) do
    "hello #{atom}"
  end
end
