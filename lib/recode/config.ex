defmodule Recode.Config do
  @moduledoc """
  This moudle reads the `Recode` configuration.
  """

  @type config :: keyword()

  @config ".recode.exs"

  @spec read(Path.t() | opts) :: {:ok, config()} | {:error, :not_found} when opts: keyword()
  def read(path) when is_binary(path) do
    case File.exists?(path) do
      true ->
        config = path |> Code.eval_file() |> elem(0)
        {:ok, config}

      false ->
        {:error, :not_found}
    end
  end

  def read(opts) when is_list(opts) do
    opts
    |> Keyword.get(:config, @config)
    |> read()
  end
end
