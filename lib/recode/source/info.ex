defmodule Recode.Source.Info do
  # TODO: This module is obsolete. It is just used to extract all moudles from
  #       code. This should be just a function or a differen module (maybe Recode.Code.modules/1)

  alias Recode.Context
  alias Recode.Source
  alias Recode.Source.Info
  alias Sourceror.Zipper

  defstruct [
    :module,
    :definitions,
    :requirements,
    :usages,
    :imports,
    :aliases
  ]

  def from_context(%Context{} = context) do
    struct!(Info,
      module: context.module,
      definitions: definitions(context),
      usages: context.usages,
      aliases: context.aliases,
      imports: context.imports,
      requirements: context.requirements
    )
  end

  def new(%Source{code: code}), do: from_code(code)

  def from_code(code) do
    code
    |> Sourceror.parse_string!()
    |> Zipper.zip()
    |> Context.traverse(%{}, fn zipper, context, acc ->
      {zipper, context, put(acc, context)}
    end)
    |> elem(1)
    |> Map.values()
  end

  defp put(map, %Context{module: nil}), do: map

  defp put(map, %Context{module: []}), do: map

  defp put(map, %Context{module: module} = context) do
    module_info = from_context(context)

    Map.update(map, module, module_info, fn existing_value ->
      update(existing_value, module_info)
    end)
  end

  def update(%Info{module: module} = old, %Info{module: module} = new) do
    %Info{new | definitions: Enum.uniq(old.definitions ++ new.definitions)}
  end

  defp definitions(%Context{definition: nil}), do: []

  defp definitions(%Context{definition: definition}), do: [definition]

  def mfa(%Info{module: module} = module_info, {nil, fun, arity} = mfa) do
    case has_definition?(module_info, mfa) do
      true -> {module, fun, arity}
      false -> mfa
    end
  end

  def mfa(%Info{aliases: aliases}, {alias, fun, arity}) do
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

  def has_definition?(%Info{definitions: definitions}, {nil, fun, arity}) do
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
