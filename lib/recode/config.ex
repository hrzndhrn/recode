defmodule Recode.Config do
  @moduledoc """
  This moudle reads the `Recode` configuration.
  """

  @type config :: keyword()

  @spec read(Path.t()) :: config()
  def read(path) do
    case File.exists?(path) do
      true ->
        config = path |> Code.eval_file() |> elem(0)
        {:ok, config}

      false ->
        {:error, :not_found}
    end
  end
end
