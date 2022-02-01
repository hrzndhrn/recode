defmodule Recode.ModuleInfo do
  @moduledoc """
  TODO
  """

  alias Recode.Context
  alias Recode.ModuleInfo

  defstruct [
    :module,
    :definitions,
    :requirements,
    :usages,
    :imports,
    :aliases,
    file: nil
  ]

  def from_context(%Context{} = context) do
    struct!(ModuleInfo,
      module: Module.concat(context.module),
      definitions: definitions(context),
      usages: context.usages,
      aliases: context.aliases,
      imports: context.imports,
      requirements: context.requirements
    )
  end

  def update(%ModuleInfo{module: module} = old, %ModuleInfo{module: module} = new) do
    %ModuleInfo{new | definitions: Enum.uniq(old.definitions ++ new.definitions)}
  end

  defp definitions(%Context{definition: nil}), do: []

  defp definitions(%Context{definition: definition}), do: [definition]

  def mfa(%ModuleInfo{module: module} = module_info, {nil, fun, arity} = mfa) do
    case has_definition?(module_info, mfa) do
      true -> {module, fun, arity}
      false -> mfa
    end
  end

  def mfa(%ModuleInfo{aliases: aliases}, {alias, fun, arity}) do
    path =
      Enum.find_value(aliases, alias, fn {path, opts} ->
        cond do
          as?(opts, alias) -> path
          ends_with?(path, alias) -> path
          true -> false
        end
      end)

    {Module.concat(path), fun, arity}
  end

  def has_definition?(%ModuleInfo{definitions: definitions}, {nil, fun, arity}) do
    Enum.find_value(definitions, false, fn
      {_kind, ^fun, ^arity} -> true
      _definition -> false
    end)
  end

  defp as?(nil, _alias), do: false

  defp as?(opts, [as]) do
    Keyword.get(opts, :as) == Module.concat("Elixir", as)
  end

  defp as?(_opts, _alias), do: false

  defp ends_with?(list, suffix) when is_list(list) and is_list(suffix) do
    suffix == Enum.drop(list, length(list) - length(suffix))
  end
end
