defmodule Recode.Task do
  @moduledoc """
  The behaviour for a `recode` task.
  """

  alias Rewrite.Source

  @doc """
  Applies a task with the given `source` and `opts`.
  """
  @callback run(source :: Source.t(), opts :: Keyword.t()) :: Source.t()

  @doc """
  Returns the configuration for the given `key`.
  """
  @callback config(key :: :check | :correct | :refactor) :: boolean

  @optional_callbacks config: 1

  defmacro __using__(opts) do
    config = Keyword.validate!(opts, check: false, correct: false)

    quote do
      @behaviour Recode.Task

      @config unquote(config)

      for name <- [:shortdoc, :category] do
        Module.register_attribute(__MODULE__, name, persist: true)
      end

      @doc """
      Returns the config entry for the given key.
      """
      def config(key) when key in [:check, :correct] do
        Keyword.fetch!(@config, key)
      end

      @doc """
      Returns the shortdoc for recode task.

      Returns `nil` if `@shortdoc` is not available.
      """
      def shortdoc, do: attribute(:shortdoc)

      @doc """
      Returns the category for recode task.

      Returns `nil` if `@catgoey` is not available.
      """
      def category, do: attribute(:category)

      defp attribute(key) do
        with [shortdoc] <- Keyword.get(__MODULE__.__info__(:attributes), key) do
          shortdoc
        end
      end
    end
  end
end
