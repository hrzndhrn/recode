defmodule Recode.Project do
  @moduledoc """
  The `%Project{}` conatins all `Recode.Sources` of a project.
  """

  alias Recode.Project
  alias Recode.ProjectError
  alias Recode.Source

  require Logger

  defstruct sources: %{}, paths: %{}, modules: %{}, inputs: []

  @type id :: reference()

  @type t :: %Project{
          sources: %{id() => Source.t()},
          paths: %{Path.t() => id()},
          inputs: [Path.t()]
        }

  @doc """
  Creates a `%Project{}` from the given `inputs`.

  The `inputs` can also contain wildcards.

  ## Examples

      iex> alias Recode.Project
  """
  @spec new(Path.t() | [Path.t()]) :: t()
  def new(inputs) do
    inputs = inputs |> List.wrap() |> Enum.flat_map(&Path.wildcard/1)

    {sources, paths} =
      Enum.reduce(inputs, {%{}, %{}}, fn path, {sources, paths} ->
        source = Source.new!(path)
        update_internals({sources, paths}, source)
      end)

    struct!(Project, sources: sources, paths: paths, inputs: inputs)
  end

  @doc ~S"""
  Creates a `%Project{}` from the given sources.
  """
  def from_sources(sources) do
    {sources, paths} =
      Enum.reduce(sources, {%{}, %{}}, fn source, {sources, paths} ->
        update_internals({sources, paths}, source)
      end)

    struct!(Project, sources: sources, paths: paths, inputs: nil)
  end

  @doc ~S'''
  Returns a `%Source{}` for the given `key`.

  The key could be a path or an id. For path keys, the most recent file is
  returned.

  ## Examples

      iex> source = Source.from_string(
      ...>    """
      ...>    defmodule MyApp.Mode do
      ...>    end
      ...>    """,
      ...>    "my_app/mode.ex"
      ...> )
      iex> project = Project.from_sources([source])
      iex> Project.source(project, "my_app/mode.ex")
      {:ok, source}
      iex> Project.source(project, source.id)
      {:ok, source}
      iex> Project.source(project, "foo")
      :error

      iex> source = Source.from_string(":a", "a.ex")
      iex> project = Project.from_sources(
      ...>   [source, Source.from_string(":b", "b.ex")]
      ...> )
      iex> update = Source.update(source, :test, path: "b.ex")
      iex> project = Project.update(project, update)
      iex> Project.source(project, "a.ex")
      {:ok, update}
      iex> Project.source(project, "b.ex")
      {:ok, update}
  '''
  @spec source(t(), key) :: {:ok, Source.t()} | :error
        when key: id() | Path.t()
  def source(%Project{sources: sources}, key) when is_reference(key) do
    Map.fetch(sources, key)
  end

  def source(%Project{sources: sources, paths: paths}, key) when is_binary(key) do
    with {:ok, id} <- Map.fetch(paths, key) do
      Map.fetch(sources, id)
    end
  end

  @doc """
  Same as `source/2` but raises on error.
  """
  @spec source!(t(), key) :: Source.t()
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
  @spec sources(t()) :: [Source.t()]
  def sources(%Project{sources: sources}) do
    sources
    |> Map.values()
    |> Enum.sort(Source)
  end

  @doc """
  Updates the `project` with the given `source`.

  If the `source` is part of the project the `source` will be replaced,
  otherwise the `source` will be added.
  """
  @spec update(t(), Source.t()) :: t()
  def update(%Project{sources: sources, paths: paths} = project, %Source{} = source) do
    case update?(project, source) do
      false ->
        project

      true ->
        {sources, paths} = update_internals({sources, paths}, source)
        %Project{project | sources: sources, paths: paths}
    end
  end

  defp update?(%Project{sources: sources}, %Source{id: id} = source) do
    case Map.fetch(sources, id) do
      {:ok, legacy} -> legacy != source
      :error -> true
    end
  end

  defp update_internals({sources, paths}, source) do
    sources = Map.put(sources, source.id, source)
    paths = Map.put(paths, source.path, source.id)

    {sources, paths}
  end

  @doc """
  Returns the unreferenced sources.

  Unreferenced source are sources whose original path is no longer part of the
  project.
  """
  @spec unreferenced(t()) :: [Source.t()]
  def unreferenced(%Project{sources: sources}) do
    {actual, orig} =
      sources
      |> Map.values()
      |> Enum.reduce({MapSet.new(), MapSet.new()}, fn source, {actual, orig} ->
        case {Source.path(source), Source.path(source, 1)} do
          {path, path} ->
            {actual, orig}

          {actual_path, orig_path} ->
            {MapSet.put(actual, actual_path), MapSet.put(orig, orig_path)}
        end
      end)

    orig
    |> MapSet.difference(actual)
    |> MapSet.to_list()
    |> Enum.sort()
  end

  @doc """
  Retruns conflicts between sources.

  Sources with the same path have a conflict.
  """
  @spec conflicts(t()) :: %{Path.t() => [Source.t()]}
  def conflicts(%Project{sources: sources}) do
    sources
    |> Map.values()
    |> conflicts(%{}, %{})
  end

  defp conflicts([], _seen, conflicts), do: conflicts

  defp conflicts([source | sources], seen, conflicts) do
    path = Source.path(source)

    case Map.fetch(conflicts, path) do
      {:ok, list} ->
        conflicts = Map.put(conflicts, path, [source | list])
        conflicts(sources, seen, conflicts)

      :error ->
        case Map.fetch(seen, path) do
          {:ok, item} ->
            seen = Map.delete(seen, path)
            conflicts = Map.put(conflicts, path, [source, item])
            conflicts(sources, seen, conflicts)

          :error ->
            seen = Map.put(seen, path, source)
            conflicts(sources, seen, conflicts)
        end
    end
  end

  @doc """
  Returns `true` if any source has one or more issues.
  """
  @spec issues?(t) :: boolean
  def issues?(%Project{sources: sources}) do
    sources
    |> Map.values()
    |> Enum.any?(fn %Source{issues: issues} -> not Enum.empty?(issues) end)
  end

  @doc """
  Counts the items of the given `type` in the `project`.

  The `type` `:sources` returns the count for all sources in the project,
  including scripts.

  The `type` `:scripts` returns the count of all sources with a path that ends
  with `".exs"`.
  """
  @spec count(t, type :: :sources | :scripts) :: non_neg_integer
  def count(%Project{sources: sources}, :sources), do: map_size(sources)

  def count(%Project{paths: paths}, :scripts) do
    paths
    |> Map.keys()
    |> Enum.filter(fn
      nil -> false
      path -> String.ends_with?(path, ".exs")
    end)
    |> Enum.count()
  end

  @doc """
  Return a `%Project{}` where each `source` is the result of invoking `fun` on
  each `source` of the given `project`.

  The optional `opts` becomes the second argument of `fun`.

  The `fun` must return `{:ok, source}` to update the `project` or `:error` to
  skip the update of the `source`.
  """
  @spec map(t(), opts, fun) :: t()
        when opts:
               term()
               | nil,
             fun:
               (Source.t() -> Source.t())
               | (Source.t(), term() -> Source.t())
  def map(%Project{} = project, opts \\ nil, fun) do
    map(project, sources(project), fun, opts)
  end

  defp map(project, [], _fun, _opts), do: project

  defp map(project, [source | sources], fun, opts) do
    source = map_apply(source, fun, opts)
    project = update(project, source)

    map(project, sources, fun, opts)
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))
      map(project, sources, fun, opts)
  end

  defp map_apply(source, fun, nil), do: fun.(source)

  defp map_apply(source, fun, opts), do: fun.(source, opts)

  @doc """
  Saves all sources in the `project` to disk.

  This function call `Recode.Source.save/1` on all sources in the `project`.

  The optional second argument accepts a list of paths for files to be excluded.
  """
  @spec save(t(), [Path.t()]) ::
          :ok | {:error, :conflicts | {Path.t(), File.posix()}}
  def save(%Project{sources: sources} = project, exclude \\ []) do
    with :ok <- conflict_free(project, exclude) do
      result =
        sources
        |> Map.values()
        |> Enum.reduce([], fn source, errors ->
          save(source, exclude, errors)
        end)

      case result do
        [] -> :ok
        errors -> {:error, errors}
      end
    end
  end

  defp save(source, exclude, errors) do
    case write?(source, exclude) do
      false ->
        errors

      true ->
        case Source.save(source) do
          :ok -> errors
          {:error, :nofile} -> errors
          {:error, reason} -> [{source.path, reason} | errors]
        end
    end
  end

  defp conflict_free(project, exclude) do
    conflicts =
      project
      |> conflicts()
      |> Map.keys()
      |> Enum.reject(fn conflict -> conflict in exclude end)

    case conflicts do
      [] -> :ok
      _list -> {:error, :conflicts}
    end
  end

  defp write?(%Source{path: path}, exclude), do: path not in exclude
end
