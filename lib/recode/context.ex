defmodule Recode.Context do
  @moduledoc """
  TODO: @moduledoc
  """

  import Recode.Utils, only: [ends_with?: 2]

  alias Recode.Context
  alias Sourceror.Zipper

  # TODO: add @moduledoc, @doc, @spec

  defstruct module: nil,
            aliases: [],
            imports: [],
            usages: [],
            requirements: [],
            definition: nil,
            assigns: %{}

  def module(%Context{module: nil}), do: nil

  def module(%Context{module: {name, _meta}}), do: name

  def expand_mfa(%Context{aliases: aliases}, {module, fun, arity}) do
    with {:ok, alias} <- find_alias(aliases, module) do
      {:ok, {alias, fun, arity}}
    end
  end

  def assign(%Context{assigns: assigns} = context, key, value) when is_atom(key) do
    %{context | assigns: Map.put(assigns, key, value)}
  end

  def assigns(%Context{assigns: data} = context, assigns) do
    %{context | assigns: Map.merge(data, assigns)}
  end

  def traverse(zipper, fun) when is_function(fun, 2) do
    zipper
    |> run_traverse(%Context{}, fun)
    |> elem(0)
  end

  def traverse(zipper, acc, fun) when is_function(fun, 3) do
    {zipper, {_context, acc}} = run_traverse(zipper, %Context{}, acc, fun)
    {zipper, acc}
  end

  # helpers for traverse/3

  defp run_traverse(zipper, context, fun) do
    Zipper.traverse_while(zipper, context, fn zipper, context ->
      do_traverse(zipper, context, fun)
    end)
  end

  defp do_traverse({{:alias, meta, args}, _zipper_meta} = zipper, context, fun)
       when not is_nil(args) do
    aliases = get_aliases(args, meta)
    context = add_aliases(context, aliases)

    cont(zipper, context, fun)
  end

  defp do_traverse({{:import, meta, [arg, opts]}, _} = zipper, context, fun) do
    import = get_alias(arg)
    opts = eval(opts)
    context = add_import(context, {import, meta, opts})

    cont(zipper, context, fun)
  end

  defp do_traverse({{:import, meta, [arg]}, _} = zipper, context, fun) do
    import = get_alias(arg)
    context = add_import(context, {import, meta, nil})

    cont(zipper, context, fun)
  end

  defp do_traverse({{:use, meta, [arg, opts]}, _} = zipper, context, fun) do
    use = get_alias(arg)
    opts = eval(opts)
    context = add_use(context, {use, meta, opts})

    cont(zipper, context, fun)
  end

  defp do_traverse({{:use, meta, [arg]}, _} = zipper, context, fun) do
    use = get_alias(arg)
    context = add_use(context, {use, meta, nil})

    cont(zipper, context, fun)
  end

  defp do_traverse({{:require, meta, [arg, opts]}, _} = zipper, context, fun) do
    require = get_alias(arg)
    opts = eval(opts)
    context = add_require(context, {require, meta, opts})

    cont(zipper, context, fun)
  end

  defp do_traverse({{:require, meta, [arg]}, _} = zipper, context, fun) do
    require = get_alias(arg)
    context = add_require(context, {require, meta, nil})

    cont(zipper, context, fun)
  end

  defp do_traverse({{:defmodule, meta, [{:__aliases__, _, name} | _]}, _} = zipper, context, fun) do
    case module(context, :meta) == meta do
      true ->
        cont(zipper, context, fun)

      false ->
        module = module_concat(context, Module.concat(name))
        do_traverse_sub(zipper, context, fun, module: {module, meta})
    end
  end

  defp do_traverse({{definition, meta, args}, _} = zipper, context, fun)
       when definition in [:def, :defp, :defmacro, :defmacrop] and not is_nil(args) do
    case definition(context, :meta) == meta do
      true ->
        cont(zipper, context, fun)

      false ->
        definition = get_definition(definition, args)
        do_traverse_sub(zipper, context, fun, definition: {definition, meta})
    end
  end

  defp do_traverse(zipper, context, fun) do
    cont(zipper, context, fun)
  end

  defp do_traverse_sub(zipper, context, fun, [{key, value}]) do
    sub_context = Map.put(context, key, value)
    sub_zipper = sub_zipper(zipper)
    {{ast, _}, %Context{assigns: assigns}} = run_traverse(sub_zipper, sub_context, fun)
    zipper = Zipper.replace(zipper, ast)
    context = Context.assigns(context, assigns)
    {:skip, zipper, context}
  end

  # helpers for traverse/4

  defp run_traverse(zipper, context, acc, fun) do
    Zipper.traverse_while(zipper, {context, acc}, fn zipper, {context, acc} ->
      do_traverse(zipper, context, acc, fun)
    end)
  end

  defp do_traverse({{:alias, meta, args}, _} = zipper, context, acc, fun) when not is_nil(args) do
    aliases = get_aliases(args, meta)
    context = add_aliases(context, aliases)

    cont(zipper, context, acc, fun)
  end

  defp do_traverse({{:import, meta, [arg, opts]}, _} = zipper, context, acc, fun) do
    import = get_alias(arg)
    opts = eval(opts)
    context = add_import(context, {import, meta, opts})

    cont(zipper, context, acc, fun)
  end

  defp do_traverse({{:import, meta, [arg]}, _} = zipper, context, acc, fun) do
    import = get_alias(arg)
    context = add_import(context, {import, meta, nil})

    cont(zipper, context, acc, fun)
  end

  defp do_traverse({{:use, meta, [arg, opts]}, _} = zipper, context, acc, fun) do
    use = get_alias(arg)
    opts = eval(opts)
    context = add_use(context, {use, meta, opts})

    cont(zipper, context, acc, fun)
  end

  defp do_traverse({{:use, meta, [arg]}, _} = zipper, context, acc, fun) do
    use = get_alias(arg)
    context = add_use(context, {use, meta, nil})

    cont(zipper, context, acc, fun)
  end

  defp do_traverse({{:require, meta, [arg, opts]}, _} = zipper, context, acc, fun) do
    require = get_alias(arg)
    opts = eval(opts)
    context = add_require(context, {require, meta, opts})

    cont(zipper, context, acc, fun)
  end

  defp do_traverse({{:require, meta, [arg]}, _} = zipper, context, acc, fun) do
    require = get_alias(arg)
    context = add_require(context, {require, meta, nil})

    cont(zipper, context, acc, fun)
  end

  defp do_traverse(
         {{:defmodule, meta, [{:__aliases__, _, name} | _]}, _} = zipper,
         context,
         acc,
         fun
       ) do
    case module(context, :meta) == meta do
      true ->
        cont(zipper, context, acc, fun)

      false ->
        module = module_concat(context, Module.concat(name))
        do_traverse_sub(zipper, context, acc, fun, module: {module, meta})
    end
  end

  defp do_traverse({{definition, meta, args}, _zipper_meta} = zipper, context, acc, fun)
       when definition in [:def, :defp, :defmacro, :defmacrop] and length(args) == 2 do
    case definition(context, :meta) == meta do
      true ->
        cont(zipper, context, acc, fun)

      false ->
        definition = get_definition(definition, args)
        do_traverse_sub(zipper, context, acc, fun, definition: {definition, meta})
    end
  end

  defp do_traverse(zipper, context, acc, fun) do
    cont(zipper, context, acc, fun)
  end

  defp do_traverse_sub(zipper, context, acc, fun, [{key, value}]) do
    sub_context = Map.put(context, key, value)
    sub_zipper = sub_zipper(zipper)

    {{ast, _}, {%Context{assigns: assigns}, acc}} =
      run_traverse(sub_zipper, sub_context, acc, fun)

    zipper = Zipper.replace(zipper, ast)
    context = Context.assigns(context, assigns)
    {:skip, zipper, {context, acc}}
  end

  # other helpers

  defp eval(ast) do
    ast |> Code.eval_quoted() |> elem(0)
  end

  defp get_definition(kind, [{:when, _meta1, [{name, _meta2, args}, _expr]}, _block]) do
    {kind, name, length(args)}
  end

  defp get_definition(kind, [{name, _meta, args}]) do
    {kind, name, length(args)}
  end

  defp get_definition(kind, [{name, _meta, nil}, _expr]) do
    {kind, name, 0}
  end

  defp get_definition(kind, [{name, _meta, args}, _expr]) do
    {kind, name, length(args)}
  end

  defp get_alias({:__aliases__, _meta, name}) do
    Module.concat(name)
  end

  defp get_aliases([{{:., _, [alias, :{}]}, _, aliases}], meta) do
    base = get_alias(alias)

    Enum.map(aliases, fn alias ->
      {Module.concat(base, get_alias(alias)), meta, nil}
    end)
  end

  defp get_aliases([arg], meta), do: [{get_alias(arg), meta, nil}]

  defp get_aliases([arg, opts], meta), do: [{get_alias(arg), meta, eval(opts)}]

  defp cont(zipper, context, fun) do
    {zipper, context} = fun.(zipper, context)
    {:cont, zipper, context}
  end

  defp cont(zipper, context, acc, fun) do
    {zipper, context, acc} = fun.(zipper, context, acc)
    {:cont, zipper, {context, acc}}
  end

  defp sub_zipper({ast, _meta}), do: {ast, nil}

  defp find_alias(aliases, module) do
    Enum.find_value(aliases, :error, fn
      {alias, _meta, nil} ->
        case ends_with?(alias, module) do
          false -> false
          true -> {:ok, alias}
        end

      {alias, _meta, opts} ->
        case Keyword.get(opts, :as, :none) == module do
          false -> false
          true -> {:ok, alias}
        end
    end)
  end

  defp definition(%Context{definition: nil}, :meta), do: nil

  defp definition(%Context{definition: {_definition, meta}}, :meta), do: meta

  defp add_aliases(%Context{aliases: aliases} = context, list) do
    %Context{context | aliases: aliases ++ list}
  end

  defp add_import(%Context{imports: imports} = context, import) do
    %Context{context | imports: imports ++ [import]}
  end

  defp add_use(%Context{usages: usages} = context, use) do
    %Context{context | usages: usages ++ [use]}
  end

  defp add_require(%Context{requirements: requirements} = context, require) do
    %Context{context | requirements: requirements ++ [require]}
  end

  defp module(%Context{module: nil}, :meta), do: nil

  defp module(%Context{module: {_name, meta}}, :meta), do: meta

  defp module_concat(%Context{module: nil}, module), do: module

  defp module_concat(%Context{module: {module1, _meta}}, module2) do
    Module.concat(module1, module2)
  end
end
