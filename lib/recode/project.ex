defmodule Recode.Project do
  @moduledoc """
  TODO: extend docs
  A map with all modules and all infos to the module.
  """

  alias Recode.Context
  alias Recode.ModuleInfo
  alias Sourceror.Zipper

  def new(files) when is_list(files) do
    Enum.reduce(files, %{}, fn file, acc ->
      file
      |> read()
      |> Enum.into(%{}, fn {key, value} -> {key, Map.put(value, :file, file)} end)
      |> Map.merge(acc)
    end)
  end

  def mfa(project, context, mfa) when is_map(project) do
    case fetch_module_info(project, context.module) do
      {:ok, module_info} ->
        with {nil, _fun, _arity} <- ModuleInfo.mfa(module_info, mfa) do
          mfa(:import, project, module_info, mfa)
        end

      :error ->
        mfa
    end
  end

  defp mfa(:import, _project, %ModuleInfo{imports: []}, mfa), do: mfa

  defp mfa(:import, project, %ModuleInfo{imports: imports}, {nil, fun, arity} = mfa) do
    module =
      Enum.find_value(imports, fn {path, _opts} ->
        case fetch_module_info(project, path) do
          {:ok, module_info} ->
            with true <- ModuleInfo.has_definition?(module_info, mfa) do
              module_info.module
            end

          :error ->
            false
        end
      end)

    {module, fun, arity}
  end

  def fetch_module_info(project, module) when is_map(project) do
    Map.fetch(project, module)
  end

  defp read(file) do
    file
    |> File.read!()
    |> Sourceror.parse_string!()
    |> Zipper.zip()
    |> Recode.traverse(%{}, fn zipper, context, acc ->
      {zipper, context, put(acc, context)}
    end)
    |> elem(1)
  end

  defp put(map, %Context{module: nil}), do: map

  defp put(map, %Context{module: []}), do: map

  defp put(map, %Context{module: module} = context) do
    module_info = ModuleInfo.from_context(context)

    Map.update(map, module, module_info, fn existing_value ->
      ModuleInfo.update(existing_value, module_info)
    end)
  end
end
