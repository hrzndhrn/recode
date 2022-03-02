defmodule Recode.Context do
  alias Recode.Context
  alias Sourceror.Zipper

  # TODO: add @moduledoc, @doc, @spec
  # TODO: add key file to struct

  defstruct module: nil,
            aliases: [],
            imports: [],
            usages: [],
            requirements: [],
            definition: nil,
            assigns: %{}

  # TODO: Most of this functions could be private because they are just called
  #       by traverse

  @deprecated "obsolete?"
  def fa(%Context{definition: {{_kind, fun, arity}, _meta}}), do: {fun, arity}

  def module(%Context{module: nil}), do: nil

  def module(%Context{module: {name, _meta}}), do: name

  defp module(%Context{module: nil}, :meta), do: nil

  defp module(%Context{module: {_name, meta}}, :meta), do: meta

  defp module_concat(%Context{module: nil}, module), do: module

  defp module_concat(%Context{module: {module1, _meta}}, module2) do
    Module.concat(module1, module2)
  end

  def expand_mfa(%Context{aliases: aliases}, {module, fun, arity}) do
    with {:ok, alias} <- find_alias(aliases, module) do
      {:ok, {alias, fun, arity}}
    end
  end

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

  # TODO: ends_with? is duplicated in this project
  defp ends_with?(module1, module2) when is_atom(module1) and is_atom(module2) do
    module1 = Module.split(module1)
    module2 = Module.split(module2)

    ends_with?(module1, module2)
  end

  defp ends_with?(list, postfix) do
    case length(list) - length(postfix) do
      diff when diff < 0 -> false
      diff -> Enum.drop(list, diff) == postfix
    end
  end

  @deprecated "use expand_mfa"
  def as(%Context{aliases: aliases}, {module, fun, arity}) do
    with {:ok, alias} <- find_as(aliases, module) do
      {:ok, {alias, fun, arity}}
    end
  end

  defp find_as(aliases, module) do
    Enum.find_value(aliases, :error, fn
      {_alias, _meta, nil} ->
        false

      {alias, _meta, opts} ->
        case Keyword.get(opts, :as, :none) == module do
          false -> false
          true -> {:ok, alias}
        end
    end)
  end

  # def definition(%Context{definition: nil}), do: nil

  # def definition(%Context{definition: {kind, fun, arity}, meta}) do
  #   {}
  #   end

  defp definition(%Context{definition: nil}, :meta), do: nil

  defp definition(%Context{definition: {_definition, meta}}, :meta), do: meta

  # defp definition(%Context{} = context, definition) do
  #   %Context{context | definition: definition}
  # end

  # @deprecated "obsolete"
  # def module(%Context{} = context, module) do
  #   %Context{context | module: module}
  # end

  # @deprecated "obsolete"
  # defp nested_module(%Context{module: nil} = context, nested) do
  #   %Context{context | module: Module.concat(nested)}
  # end

  # @deprecated "obsolete"
  # defp nested_module(%Context{module: module} = context, nested) do
  #   %Context{context | module: Module.concat(module, nested)}
  # end

  # defp x_module(%Context{module: nil} = context, module) do
  #   %Context{context | module: module}
  # end

  defp add_aliases(%Context{aliases: aliases} = context, list) do
    %Context{context | aliases: aliases ++ list}
  end

  defp add_import(%Context{imports: imports} = context, import) do
    %Context{context | imports: imports ++ [import]}
  end

  def add_use(%Context{usages: usages} = context, use) do
    %Context{context | usages: usages ++ [use]}
  end

  def add_require(%Context{requirements: requirements} = context, require) do
    %Context{context | requirements: requirements ++ [require]}
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

  defp run_traverse(zipper, context, fun) do
    Zipper.traverse_while(zipper, context, fn zipper, context ->
      do_traverse(zipper, context, fun)
    end)
  end

  defp run_traverse(zipper, context, acc, fun) do
    Zipper.traverse_while(zipper, {context, acc}, fn zipper, {context, acc} ->
      do_traverse(zipper, context, acc, fun)
    end)
  end

  # do_traverse/3

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

  # do_traverse/4

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

  @deprecated "???"
  def newline(string), do: String.trim_leading(string) <> "\n"

  @deprecated "???"
  def aliases, do: []
end
