defmodule Recode.Task do
  @moduledoc """
  The behaviour for a `recode` task.
  """

  alias Rewrite.Source

  @type config :: keyword()
  @type message :: String.t()
  @type task :: module()
  @type category :: atom()

  @doc """
  Applies a task with the given `source` and `opts`.
  """
  @callback run(source :: Source.t(), opts :: Keyword.t()) :: Source.t()

  @doc """
  Sets a callback to check and manipulate `config` before any recode task runs.

  When `init` returns an error tuple, the `mix recode` task raises an exception
  with the returned `message`.
  """
  @callback init(config()) :: {:ok, config} | {:error, message()}

  # a callback for mox
  @doc false
  @callback __attributes__ :: any

  @optional_callbacks init: 1

  @doc """
  Returns `true` if the given `task` provides a check for sources.
  """
  @spec checker?(task()) :: boolean()
  def checker?(task) when is_atom(task), do: attribute(task, :checker)

  @doc """
  Returns `true` if the given `task` provides a correction functionality for
  sources.
  """
  @spec corrector?(task()) :: boolean()
  def corrector?(task) when is_atom(task), do: attribute(task, :corrector)

  @doc """
  Returns the category for the given `task`.
  """
  @spec category(task()) :: category()
  def category(task) when is_atom(task), do: attribute(task, :category)

  @doc """
  Returns the shortdoc for the given `task`.

  Returns `nil` if `@shortdoc` is not available for the `task`.
  """
  @spec shortdoc(task()) :: String.t() | nil
  def shortdoc(task) when is_atom(task), do: attribute(task, :shortdoc)

  defp attribute(task, key) when key in [:corrector, :checker, :category] do
    task.__attributes__()
    |> Keyword.fetch!(:__recode_task_config__)
    |> Keyword.fetch!(key)
  end

  defp attribute(task, key) do
    task.__attributes__()
    |> Keyword.get(key, [])
    |> unwrap()
  end

  defp unwrap([]), do: nil

  defp unwrap([value]), do: value

  defmacro __using__(opts) do
    config =
      Keyword.validate!(opts,
        checker: true,
        corrector: false,
        category: nil
      )

    quote do
      @behaviour Recode.Task

      @__recode_task_config__ unquote(config)

      Module.register_attribute(__MODULE__, :__recode_task_config__, persist: true)
      Module.register_attribute(__MODULE__, :shortdoc, persist: true)

      @impl Recode.Task
      def init(config), do: {:ok, config}

      @impl Recode.Task
      def __attributes__, do: __MODULE__.__info__(:attributes)

      defoverridable init: 1
    end
  end
end
