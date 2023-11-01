defmodule MyCode.TrailingComma do
  @moduledoc false

  def list do
    [
      100_000,
      200_000,
      300_000,
      400_000,
      500_000,
      600_000,
      700_000,
      800_000,
      900_000,
      1_000_000,
      2_000_000,
    ] |> Enum.reverse()
  end
end
