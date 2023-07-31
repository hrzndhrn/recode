defmodule MyCode.Deep do
  def abbys(stare) do
    if stare do
      cond do
        stare ->
          case stare do
            true -> :stare
            false -> :error
          end

        true ->
          :error
      end
    end
  end
end
