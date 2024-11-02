defmodule Recode.Task do
  @moduledoc """
  The behaviour for a `recode` task.

  To create a `recode` task, you'll need to:

    1. Create a module.    
    2. Call `use Recode.Task` in that module.  
    3. Implement the callbacks `c:run/2`.
    4. Optionally, `c:init/1` can also be implemented.

  > #### `use Recode.Task` {: .info}
  >
  > When you `use Recode.Task`, the `Recode.Task` module will
  > set `@behaviour Recode.Task`.
  > 
  > `Recode.Task` will also set default implementations for the callbacks 
  > `c:update_source/3` and `c:new_issue/2`.
  """

  alias Recode.Issue
  alias Rewrite.Source
  alias Sourceror.Zipper

  @type config :: keyword()
  @type message :: String.t()
  @type task :: module()
  @type category :: atom()

  @doc """
  Applies a task with the given `source` and `opts`.

  The `opts` containing:

    * The configuration for the task defined in the recode-config. When the 
      `c:init/1` is implemented then the `opts` returned by this callback are in 
      the `opts`.
   
    * `:dot_formatter` - the `%Rewrite.DotFormatter{}` for the project.

    * `:autocorrect` - a `boolean` indicating if `recode` runs in 
      auto-correction mode.
  """
  @callback run(source :: Source.t(), opts :: Keyword.t()) :: Source.t()

  @doc """
  A callback to check and manipulate `config` before any recode task runs.

  The callback receives the `config` that is set in the recode-config.

  In the implementation of this callback the `config` can be checked and 
  defaults can be set.

  When `init` returns an error tuple, the `mix recode` task raises an exception
  with the returned `message`.
  """
  @callback init(config()) :: {:ok, config} | {:error, message()}

  @doc """
  Update the given `source` with the given `updates`.

  The default implementation of this callback applies any element from the 
  `updates` keyword list to the `source` with the given `opts`. The keys 
  `:issue` and `:issues` wlll be applied with `Rewrite.Source.add_issue/2` and 
  `Rewrite.Source.add_issues/2` respectively. Any other key will be applied with
  `Rewrite.Source.update/4`, when `opts` contains `autocorrect: true`.

  In `updates` the value for `:quoted` can be a `Sourceror.Zipper`. In this case
  the `source` is updated with the return value of `Sourceror.Zipper.root/1`.

  The `opts` are extended by `by: __MODULE__`.
  """
  @callback update_source(Source.t(), opts :: Keyword.t(), updates :: Keyword.t()) :: Source.t()

  @doc """
  Creates a new issue with the given `message` and `opts`.

  The default implementation of this callback creates an `Recode.Issue` struct
  with `reporter: __MODULE__`.
  """
  @callback new_issue(message :: String.t(), opts :: Keyword.t()) :: Issue.t()

  @doc """
  Creates a new issue with the given `opts`.

  The default implementation of this callback creates an `Recode.Issue` struct
  with `reporter: __MODULE__`.
  """
  @callback new_issue(opts :: Keyword.t()) :: Issue.t()

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

  @doc false
  def update_source(source, opts, updates, module) do
    Enum.reduce(updates, source, fn
      {:issue, issue}, source ->
        Source.add_issue(source, issue)

      {:issues, issues}, source ->
        Source.add_issues(source, issues)

      {key, value}, source ->
        if opts[:autocorrect] do
          do_update_source(source, key, value, Keyword.put(opts, :by, module))
        else
          source
        end
    end)
  end

  defp do_update_source(source, :quoted, %Zipper{} = zipper, opts) do
    do_update_source(source, :quoted, Zipper.root(zipper), opts)
  end

  defp do_update_source(source, key, value, opts) do
    Source.update(source, key, value, opts)
  end

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
      def update_source(%Source{} = source, opts, updates) do
        Recode.Task.update_source(source, opts, updates, __MODULE__)
      end

      @impl Recode.Task
      def new_issue(message, opts \\ []) do
        Recode.Issue.new(__MODULE__, message, opts)
      end

      @impl Recode.Task
      def __attributes__, do: __MODULE__.__info__(:attributes)

      defoverridable init: 1, update_source: 3, new_issue: 1, new_issue: 2
    end
  end
end
