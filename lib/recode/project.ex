defmodule Recode.Project do
  @moduledoc """
  The `%Project{}` conatins all `Recode.Sources` of a project.
  """

  alias Recode.Project
  alias Recode.ProjectError
  alias Recode.Source

  defstruct [:sources, :paths, :modules, :inputs]

  @type id :: reference()

  @type t :: [
          sources: %{id() => Source.t()},
          paths: %{Path.t() => id()},
          modules: %{module() => id()},
          inputs: [Path.t()]
        ]

  @doc """
  Creates a `%Project{}` from the given `inputs`.

  The `inputs` can also contain wildcards.

  ## Examples

  ```elixir
  iex> alias Recode.Project
  iex> Project.new(["{config,lib,test}/**/*.{ex,exs}"])
  ```
  """
  @spec new(Path.t() | [Path.t()]) :: Project.t()
  def new(inputs) do
    inputs = inputs |> List.wrap() |> Enum.flat_map(&Path.wildcard/1)

    {sources, paths, modules} =
      Enum.reduce(inputs, {%{}, %{}, %{}}, fn path, {sources, paths, modules} ->
        source = Source.new!(path)
        update_internals({sources, paths, modules}, source)
      end)

    struct!(Project, sources: sources, paths: paths, modules: modules, inputs: inputs)
  end

  @doc ~S"""
  Creates a `%Project{}` from the given sources.

  ## Examples

  ```elixir
  iex> alias Recode.{Project, Source}
  iex> source = Source.new!("test/fixtures/source/simple.ex")
  iex> Project.from_sources([source])
  %Recode.Project{
    inputs: nil,
    modules: %{MyApp.Simple => #Reference<0.3098614428.1513357316.103022>},
    paths: %{
      "test/fixtures/source/simple.ex" => #Reference<0.3098614428.1513357316.103022>
    },
    sources: %{
      #Reference<0.3098614428.1513357316.103022> => %Recode.Source{
        code: "defmodule MyApp.Simple do\n  def foo(x) do\n    x * 2\n  end\nend\n",
        hash: <<18, 138, 84, 91, 124, 40, 73, 73, 112, 63, 208, 184, 131, 192,
          123, 102>>,
        id: #Reference<0.3098614428.1513357316.103022>,
        issues: [],
        modules: [MyApp.Simple],
        path: "test/fixtures/source/simple.ex",
        versions: []
      }
    }
  }
  ```
  """
  def from_sources(sources) do
    {sources, paths, modules} =
      Enum.reduce(sources, {%{}, %{}, %{}}, fn source, {sources, paths, modules} ->
        update_internals({sources, paths, modules}, source)
      end)

    struct!(Project, sources: sources, paths: paths, modules: modules, inputs: nil)
  end

  @doc """
  Returns a `%Source{}` for the given key.

  The key could be a moudle, path or an id.
  """
  @spec source(Porject.t(), key) :: {:ok, Source.t()} | :error
        when key: id() | Path.t() | module()
  def source(%Project{sources: sources}, key) when is_reference(key) do
    Map.fetch(sources, key)
  end

  def source(%Project{sources: sources, modules: modules}, key) when is_atom(key) do
    with {:ok, id} <- Map.fetch(modules, key) do
      Map.fetch(sources, id)
    end
  end

  def source(%Project{sources: sources, paths: paths}, key) when is_binary(key) do
    with {:ok, id} <- Map.fetch(paths, key) do
      Map.fetch(sources, id)
    end
  end

  @doc """
  Same as `source/2` but raises on error.
  """
  @spec source!(Porject.t(), key) :: Source.t()
        when key: id() | Path.t() | module()
  def source!(%Project{} = project, key) do
    case source(project, key) do
      {:ok, source} -> source
      :error -> raise ProjectError, "No source for #{inspect(key)} found."
    end
  end

  @doc """
  Returns all sources sorted by path.
  """
  @spec sources(Project.t()) :: [Source.t()]
  def sources(%Project{paths: paths, sources: sources}) do
    paths
    |> Enum.sort()
    |> Enum.map(fn {_path, id} ->
      Map.fetch!(sources, id)
    end)
  end

  @doc """
  Updates the `project` with the given `source`.

  If the `source` is part of the project the `source` will be replaced,
  otherwise the `source` will be added.
  """
  @spec update(Project.t(), Source.t()) :: Project.t()
  def update(
        %Project{sources: sources, paths: paths, modules: modules} = project,
        %Source{} = source
      ) do
    case update?(project, source) do
      false ->
        project

      true ->
        {sources, paths, modules} = update_internals({sources, paths, modules}, source)
        %Project{project | sources: sources, paths: paths, modules: modules}
    end
  end

  defp update?(%Project{sources: sources}, %Source{id: id} = source) do
    case Map.fetch(sources, id) do
      {:ok, legacy} -> legacy != source
      :error -> true
    end
  end

  defp update_internals({sources, paths, modules}, source) do
    sources = Map.put(sources, source.id, source)
    paths = Map.put(paths, source.path, source.id)

    modules =
      source.modules
      |> Enum.into(%{}, fn module -> {module, source.id} end)
      |> Map.merge(modules)

    {sources, paths, modules}
  end

  @doc """
  Return a `%Project{}` where each `source` is the result of invoking `fun` on
  each `source` of the given `project`.

  The optional `opts` becomes the second argument of `fun`.

  The `fun` must return `{:ok, source}` to update the `project` or `:error` to
  skip the update of the `source`.
  """
  @spec map(Project.t(), opts, fun) :: Project.t()
        when opts: term(),
             fun:
               (Source.t() -> {:ok, Source.t()} | :error)
               | (Source.t(), opts -> {:ok, Source.t()} | :error)
  def map(%Project{sources: sources} = project, opts \\ nil, fun) do
    sources = sources |> Map.values() |> Enum.sort()
    map(project, sources, fun, opts)
  end

  defp map(project, [], _fun, _opts), do: project

  defp map(project, [source | sources], fun, opts) do
    case map_apply(source, fun, opts) do
      :error ->
        map(project, sources, fun, opts)

      {:ok, source} ->
        project = update(project, source)
        map(project, sources, fun, opts)
    end
  end

  defp map_apply(source, fun, nil), do: fun.(source)

  defp map_apply(source, fun, opts), do: fun.(source, opts)
end
