defmodule Recode.Project do
  @moduledoc """
  TODO: @moduledoc
  TODO: @docs
  TODO: @specs
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

  def new(inputs) when is_list(inputs) do
    inputs = Enum.flat_map(inputs, &Path.wildcard/1)

    {sources, paths, modules} =
      Enum.reduce(inputs, {%{}, %{}, %{}}, fn path, {sources, paths, modules} ->
        source = Source.new!(path)
        update_internals({sources, paths, modules}, source)
      end)

    struct!(Project, sources: sources, paths: paths, modules: modules, inputs: inputs)
  end

  def from_sources(sources) do
    {sources, paths, modules} =
      Enum.reduce(sources, {%{}, %{}, %{}}, fn source, {sources, paths, modules} ->
        update_internals({sources, paths, modules}, source)
      end)

    struct!(Project, sources: sources, paths: paths, modules: modules, inputs: nil)
  end

  def source_by_id!(%Project{sources: sources}, id) do
    Map.fetch!(sources, id)
  end

  def source(%Project{sources: sources, modules: modules}, module) when is_atom(module) do
    with {:ok, ref} <- Map.fetch(modules, module) do
      Map.fetch(sources, ref)
    end
  end

  def source(%Project{sources: sources, paths: paths}, path) when is_binary(path) do
    with {:ok, ref} <- Map.fetch(paths, path) do
      Map.fetch(sources, ref)
    end
  end

  def source!(%Project{} = project, key) do
    case source(project, key) do
      {:ok, source} -> source
      :error -> raise ProjectError, "No source for #{inspect(key)} found."
    end
  end

  def sources(%Project{paths: paths, sources: sources}) do
    paths
    |> Enum.sort()
    |> Enum.map(fn {_path, id} ->
      Map.fetch!(sources, id)
    end)
  end

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
