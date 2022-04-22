defmodule Recode.Context do
  @moduledoc ~S'''
  This moudle provides functions to traverse an AST with a `%Context{}`.

  ## Examples

  The following example shows the `%Context{}` for the definition of
  `MyApp.Bar.bar/1`.

      iex> alias Recode.{Source, Context}
      ...> """
      ...> defmoudle MyApp.Foo do
      ...>   def foo, do: :foo
      ...> end
      ...>
      ...> defmodule MyApp.Bar do
      ...>   alias MyApp.Foo
      ...>
      ...>   def bar(x) do
      ...>     {Foo.foo(), x}
      ...>   end
      ...> end
      ...> """
      ...> |> Source.from_string()
      ...> |> Source.zipper()
      ...> |> Context.traverse(nil, fn
      ...>   zipper, context, nil ->
      ...>     case context.definition do
      ...>       {{:def, :bar, 1}, _meta} -> {zipper, context, context}
      ...>       _def -> {zipper, context, nil}
      ...>     end
      ...>   zipper, context, acc ->
      ...>     {zipper, context, acc}
      ...> end)
      ...> |> elem(1)
      %Context{
        aliases: [
          {MyApp.Foo,
           [
             trailing_comments: [],
             leading_comments: [],
             end_of_expression: [newlines: 2, line: 6, column: 18],
             line: 6,
             column: 3
           ], nil}
        ],
        assigns: %{},
        definition:
          {{:def, :bar, 1},
           [
             trailing_comments: [],
             leading_comments: [],
             do: [line: 8, column: 14],
             end: [line: 10, column: 3],
             line: 8,
             column: 3
           ]},
        imports: [],
        module:
          {MyApp.Bar,
           [
             trailing_comments: [],
             leading_comments: [],
             do: [line: 5, column: 21],
             end: [line: 11, column: 1],
             line: 5,
             column: 1
           ]},
        requirements: [],
        usages: []
      }
  '''

  import Recode.Utils, only: [ends_with?: 2]

  alias Recode.Context
  alias Sourceror.Zipper

  defstruct module: nil,
            aliases: [],
            imports: [],
            usages: [],
            requirements: [],
            definition: nil,
            assigns: %{},
            moduledoc: nil,
            doc: nil,
            spec: nil,
            impl: nil

  @type t :: %Context{
          module: term() | nil,
          aliases: list(),
          imports: list(),
          usages: list(),
          requirements: list(),
          definition: term(),
          assigns: map(),
          moduledoc: Macro.t() | nil,
          doc: {term() | nil, Macro.t()} | nil,
          spec: {term() | nil, Macro.t()} | nil,
          impl: {term() | nil, Macro.t()} | nil
        }

  @type zipper :: Zipper.zipper()

  @doc """
  Returns the current module of a context.
  """
  @spec module(t()) :: module() | nil
  def module(%Context{module: nil}), do: nil

  def module(%Context{module: {name, _meta}}), do: name

  @doc """
  Expands the module alias for the given `mfa`.
  """
  @spec expand_mfa(t(), mfa()) :: {:ok, mfa()} | :error
  def expand_mfa(%Context{aliases: aliases}, {module, fun, arity}) do
    with {:ok, alias} <- find_alias(aliases, module) do
      {:ok, {alias, fun, arity}}
    end
  end

  @doc """
  Assigns the given `value` under `key` to the `context`.
  """
  @spec assign(t(), atom(), term()) :: t()
  def assign(%Context{assigns: assigns} = context, key, value) when is_atom(key) do
    %{context | assigns: Map.put(assigns, key, value)}
  end

  @doc """
  Returns `true` if a `spec` is availbale.
  """
  @spec spec?(t()) :: boolean
  def spec?(%Context{spec: spec}), do: not is_nil(spec)

  @doc """
  Returns `true` if an `impl` is availbale.
  """
  @spec impl?(t()) :: boolean
  def impl?(%Context{impl: impl}), do: not is_nil(impl)

  @doc """
  Returns true if `definition` satisfies the assumption.
  """
  @spec definition?(t(), :public | :visible) :: boolean()
  def definition?(%Context{definition: definition}, :public)
      when not is_nil(definition) do
    {{kind, _name, _arity}, _meta} = definition
    kind in [:def, :defmacro]
  end

  def definition?(%Context{definition: definition} = context, :visible)
      when not is_nil(definition) do
    with true <- definition?(context, :public) do
      not (doc?(context, false) or moduledoc?(context, false))
    end
  end

  @doc """
  Returns `true` if `@doc` has the given `value`.

  Usually used to check if `@doc` is set to false:
  ```elixir
  Context.moduledoc?(context, false)
  ```
  """
  @spec doc?(t(), term()) :: boolean()
  def doc?(%Context{doc: nil}, value), do: is_nil(value)

  def doc?(%Context{doc: {_to, doc}}, value) do
    attribute_value(doc) == value
  end

  @doc """
  Returns `true` if `@moduledoc` has the given `value`.

  Usually used to check if `@moduldoc` is set to false:
  ```elixir
  Context.moduledoc?(context, false)
  ```
  """
  @spec moduledoc?(t(), term()) :: boolean()
  def moduledoc?(%Context{moduledoc: nil}, value), do: is_nil(value)

  def moduledoc?(%Context{moduledoc: moduledoc}, value) do
    attribute_value(moduledoc) == value
  end

  @doc """
  Merges the given `map` to the assigns of the `context`.
  """
  @spec assigns(t(), map()) :: t()
  def assigns(%Context{assigns: assigns} = context, map) when is_map(map) do
    %{context | assigns: Map.merge(assigns, map)}
  end

  @doc """
  Traverses the given `zipper` and applys `fun` on each node.

  The `fun` gets the current `zipper` and `context` as arguments.
  """
  @spec traverse(zipper(), fun) :: zipper()
        when fun: (zipper(), t() -> {zipper(), t()})
  def traverse({_ast, _meta} = zipper, fun) when is_function(fun, 2) do
    zipper
    |> run_traverse(%Context{}, fun)
    |> elem(0)
  end

  @doc """
  Traverses the given `zipper` with an `acc` and applys `fun` on each node.
  """
  @spec traverse(zipper(), acc, fun) :: {zipper(), acc}
        when acc: term(),
             fun: (zipper(), t(), acc -> {zipper(), t(), acc})
  def traverse({_ast, _meta} = zipper, acc, fun) when is_function(fun, 3) do
    {zipper, {_context, acc}} = run_traverse(zipper, %Context{}, acc, fun)
    {zipper, acc}
  end

  # helpers for traverse/2

  defp run_traverse(zipper, context, fun) do
    Zipper.traverse_while(zipper, context, fn zipper, context ->
      do_traverse(zipper, context, fun)
    end)
  end

  defp do_traverse({{:@, _meta, _args} = attribute, _zipper_meta} = zipper, context, fun) do
    context = traverse_helper(:attribute, attribute, context)
    cont(zipper, context, fun)
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

  defp do_traverse({{:defimpl, _meta, _args}, _} = zipper, context, _fun) do
    {:skip, zipper, context}
  end

  defp do_traverse({{definition, meta, args}, _} = zipper, context, fun)
       when definition in [:def, :defp, :defmacro, :defmacrop] and not is_nil(args) do
    case definition(context, :meta) == meta do
      true ->
        cont(zipper, context, fun)

      false ->
        definition = get_definition(definition, args)
        context = update_attributes(context, definition)
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

  # helpers for traverse/3

  defp run_traverse(zipper, context, acc, fun) do
    Zipper.traverse_while(zipper, {context, acc}, fn zipper, {context, acc} ->
      do_traverse(zipper, context, acc, fun)
    end)
  end

  defp do_traverse({{:@, _meta, _args} = attribute, _zipper_meta} = zipper, context, acc, fun) do
    context = traverse_helper(:attribute, attribute, context)
    cont(zipper, context, acc, fun)
  end

  defp do_traverse({{:alias, meta, args}, _zipper_meta} = zipper, context, acc, fun)
       when not is_nil(args) do
    aliases = get_aliases(args, meta)
    context = add_aliases(context, aliases)

    cont(zipper, context, acc, fun)
  end

  defp do_traverse({{:import, meta, [arg, opts]}, _zipper_meta} = zipper, context, acc, fun) do
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

  defp do_traverse({{:defimpl, _meta, _args}, _} = zipper, context, acc, _fun) do
    {:skip, zipper, {context, acc}}
  end

  defp do_traverse({{definition, meta, args}, _zipper_meta} = zipper, context, acc, fun)
       when definition in [:def, :defp, :defmacro, :defmacrop] and length(args) == 2 do
    case definition(context, :meta) == meta do
      true ->
        cont(zipper, context, acc, fun)

      false ->
        definition = get_definition(definition, args)
        context = update_attributes(context, definition)
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

  # helpers for traverse/2/3

  defp traverse_helper(:attribute, {:@, _meta, [arg]} = attribute, context) do
    case arg do
      {:moduledoc, _meta, _args} ->
        %{context | moduledoc: attribute}

      {:doc, _meta, _args} ->
        %{context | doc: {nil, attribute}}

      {:spec, _meta, _args} ->
        %{context | spec: {nil, attribute}}

      {:impl, _meta, _args} ->
        %{context | impl: {nil, attribute}}

      _args ->
        context
    end
  end

  defp update_attributes(context, definition) do
    context
    |> update_attribute(definition, :doc)
    |> update_attribute(definition, :spec)
    |> update_attribute(definition, :impl)
  end

  defp update_attribute(context, definition, key) do
    Map.update!(context, key, fn
      {nil, value} -> {definition, value}
      {^definition, value} -> {definition, value}
      _spec -> nil
    end)
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

  defp get_alias({:__aliases__, _meta, name}) when is_list(name) do
    Module.concat(name)
  rescue
    _error -> :unknown
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

  defp attribute_value(attribute) do
    {:__block__, _meta, [value]} = attribute_block(attribute)
    value
  end

  defp attribute_block({:@, _meta1, [{_name, _meta2, [block]}]}), do: block
end
