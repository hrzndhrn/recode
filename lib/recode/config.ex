defmodule Recode.Config do
  @moduledoc """
  This module reads the `Recode` configuration.
  """

  alias Recode.Task.Format

  @type config :: keyword()

  @config ".recode.exs"

  # The minimum version of the config to run recode. This version marks the last
  # breaking change for handle the config.
  @config_min_version "0.3.0"

  @spec read(Path.t() | opts) :: {:ok, config()} | {:error, :not_found} when opts: keyword()
  def read(opts \\ [])

  def read(path) when is_binary(path) do
    case File.exists?(path) do
      true ->
        config =
          path
          |> Code.eval_file()
          |> elem(0)
          |> default(:tasks)
          |> update(:inputs)

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

  def validate(config) do
    cmp =
      config
      |> Keyword.get(:version, "0.1.0")
      |> Version.compare(@config_min_version)

    if cmp == :lt do
      {:error, :out_of_date}
    else
      :ok
    end
  end

  defp default(config, :tasks) do
    Keyword.update!(config, :tasks, fn tasks -> [{Format, []} | tasks] end)
  end

  defp update(config, :inputs) do
    Keyword.update(config, :inputs, [], fn inputs ->
      inputs |> List.wrap() |> Enum.map(fn input -> GlobEx.compile!(input) end)
    end)
  end
end
