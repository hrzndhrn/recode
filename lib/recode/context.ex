defmodule Recode.Context do
  alias Recode.Context

  defstruct module: [],
            aliases: [],
            imports: [],
            usages: [],
            requirements: [],
            definition: nil,
            assigns: %{}

  def module(%Context{} = context, module) do
    %Context{context | module: module}
  end

  def nested_module(%Context{module: module} = context, nested) do
    %Context{context | module: module ++ nested}
  end

  def add_aliases(%Context{aliases: aliases} = context, list) do
    %Context{context | aliases: aliases ++ list}
  end

  def add_import(%Context{} = context, import) do
    add_import(context, import, nil)
  end

  def add_import(%Context{imports: imports} = context, import, opts) do
    %Context{context | imports: imports ++ [{import, opts}]}
  end

  def add_use(%Context{} = context, use) do
    add_use(context, use, nil)
  end

  def add_use(%Context{usages: usages} = context, use, opts) do
    %Context{context | usages: usages ++ [{use, opts}]}
  end

  def add_require(%Context{} = context, require) do
    add_require(context, require, nil)
  end

  def add_require(%Context{requirements: requirements} = context, require, opts) do
    %Context{context | requirements: requirements ++ [{require, opts}]}
  end

  def definition(%Context{} = context, definition) do
    %Context{context | definition: definition}
  end

  def assign(%Context{assigns: assigns} = context, key, value) when is_atom(key) do
    %{context | assigns: Map.put(assigns, key, value)}
  end

  def assigns(%Context{assigns: data} = context, assigns) do
    %{context | assigns: Map.merge(data, assigns)}
  end

  def info(%Context{module: nil}, _), do: nil

  def info(%Context{module: module}, :functions) do
    do_info(module, :functions)
  end

  defp do_info(module, atom) do
    Module.concat(module).__info__(atom)
  end

  def has_function?(%Context{module: module}, {nil, _fun, _arity} = mfa) do
    do_has_function?(module, mfa)
  end

  def has_function?(%Context{module: module}, {module, _fun, _arity} = mfa) do
    do_has_function?(module, mfa)
  end

  def has_function?(%Context{}, _mfa), do: false

  defp do_has_function?(module, {_module, fun, arity}) do
    module
    |> do_info(:functions)
    |> Enum.member?({fun, arity})
  end

  # TODO: remove?????
  def mfa(%Context{} = context, {nil, fun, arity} = mfa) do
    case has_function?(context, mfa) do
      true -> {context.module, fun, arity}
      false -> mfa(:import, context, mfa)
    end
  end

  def mfa(%Context{} = context, {module, fun, arity}) do
    module =
      Enum.find_value(context.aliases, module, fn {path, as} ->
        with true <- ends_with?(path, module) or ends_with?(as, module) do
          path
        end
      end)

    {module, fun, arity}
  end

  defp mfa(:import, %Context{imports: imports}, {nil, fun, arity} = mfa) do
    module =
      Enum.find_value(imports, fn {module, _args} ->
        case do_has_function?(module, mfa) do
          true -> module
          false -> nil
        end
      end)

    {module, fun, arity}
  end

  defp ends_with?(nil, _), do: false

  defp ends_with?(list, suffix) when is_list(list) and is_list(suffix) do
    suffix == Enum.drop(list, length(list) - length(suffix))
  end
end
