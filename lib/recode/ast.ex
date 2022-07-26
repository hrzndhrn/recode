defmodule Recode.AST do
  @moduledoc """
  This module provides functions to manipulate the AST.
  """

  @doc """
  Updates the AST representing a definition.

  The keyword list `updates` can have the keys `name`, `meta` and `args`.

  ## Examples

      iex> ast = quote do
      ...>   def foo(x), do: x
      ...> end
      iex> update_definition(ast, name: :bar)
      {:def, [context: Recode.ASTTest, import: Kernel],
       [
         {:bar, [context: Recode.ASTTest], [{:x, [], Recode.ASTTest}]},
         [do: {:x, [], Recode.ASTTest}]
       ]}
      iex> update_definition(ast, meta: [])
      {:def, [],
       [
         {:foo, [context: Recode.ASTTest], [{:x, [], Recode.ASTTest}]},
         [do: {:x, [], Recode.ASTTest}]
       ]}
      iex> update_definition(ast, args: [{:y, [], Recode.ASTTest}], meta: [])
      {:def, [],
       [
         {:foo, [context: Recode.ASTTest], [{:y, [], Recode.ASTTest}]},
         [do: {:x, [], Recode.ASTTest}]
       ]}
  """
  @spec update_definition(Macro.t(), updates :: keyword()) :: Macro.t()
  def update_definition(
        {:def, meta, [{:when, meta1, [{name, meta2, args}, expr1]}, expr2]},
        updates
      ) do
    name = Keyword.get(updates, :name, name)
    meta = Keyword.get(updates, :meta, meta)
    args = Keyword.get(updates, :args, args)

    {:def, meta, [{:when, meta1, [{name, meta2, args}, expr1]}, expr2]}
  end

  def update_definition({def, meta, [{name, meta1, args}, expr]}, updates) do
    name = Keyword.get(updates, :name, name)
    meta = Keyword.get(updates, :meta, meta)
    args = Keyword.get(updates, :args, args)

    {def, meta, [{name, meta1, args}, expr]}
  end

  @doc """
  Updates a spec.

  The keyword list `updates` can have the keys `name`, `meta`, `args` and
  `return`.

  ## Examples

      iex> ast = quote do
      ...>   @spec foo(integer()) :: integer()
      ...> end
      {:@, [context: Recode.ASTTest, import: Kernel],
       [
         {:spec, [context: Recode.ASTTest],
          [{:"::", [], [{:foo, [], [{:integer, [], []}]}, {:integer, [], []}]}]}
       ]}
      iex> update_spec(ast, meta: [], name: :bar, return: {:term, [], []})
      {:@, [],
       [
         {:spec, [context: Recode.ASTTest],
          [{:"::", [], [{:bar, [], [{:integer, [], []}]}, {:term, [], []}]}]}
       ]}
  """
  @spec update_spec(Macro.t(), updates :: keyword()) :: Macro.t()
  def update_spec(
        {:@, meta,
         [
           {:spec, meta_spec,
            [
              {:"::", meta_op, [{name, meta_name, args}, return]}
            ]}
         ]},
        updates
      ) do
    name = Keyword.get(updates, :name, name)
    meta = Keyword.get(updates, :meta, meta)
    args = Keyword.get(updates, :args, args)
    return = Keyword.get(updates, :return, return)

    {:@, meta,
     [
       {:spec, meta_spec,
        [
          {:"::", meta_op, [{name, meta_name, args}, return]}
        ]}
     ]}
  end

  def update_spec(
        {:@, meta,
         [
           {:spec, meta_spec,
            [
              {:when, meta_when,
               [
                 {:"::", meta_op,
                  [
                    {name, meta_name, args},
                    return
                  ]},
                 when_block
               ]}
            ]}
         ]},
        updates
      ) do
    name = Keyword.get(updates, :name, name)
    meta = Keyword.get(updates, :meta, meta)
    args = Keyword.get(updates, :args, args)
    return = Keyword.get(updates, :return, return)

    {:@, meta,
     [
       {:spec, meta_spec,
        [
          {:when, meta_when,
           [
             {:"::", meta_op,
              [
                {name, meta_name, args},
                return
              ]},
             when_block
           ]}
        ]}
     ]}
  end

  @doc """
  Update a function call.

  The keyword list `updates` can have the keys `name`, `meta` and `args`.

  ## Examples

      iex> ast = quote do
      ...>   foo(x)
      ...> end
      iex> update_call(ast, name: :bar)
      {:bar, [], [{:x, [], Recode.ASTTest}]}
  """
  @spec update_call(Macro.t(), updates :: keyword()) :: Macro.t()
  def update_call({name, meta, args}, updates) do
    name = Keyword.get(updates, :name, name)
    meta = Keyword.get(updates, :meta, meta)
    args = Keyword.get(updates, :args, args)

    {name, meta, args}
  end

  @doc """
  Update a dotted function call.

  ## Examples

      iex> ast = quote do
      ...>   Foo.foo(x)
      ...> end
      iex> update_dot_call(ast, name: :bar)
      {{:., [], [{:__aliases__, [alias: false], [:Foo]}, :bar]}, [], [{:x, [], Recode.ASTTest}]}
  """
  @spec update_dot_call(Macro.t(), updates :: keyword()) :: Macro.t()
  def update_dot_call(
        {{:., meta, [{:__aliases__, meta1, module}, name]}, meta2, args},
        updates
      ) do
    name = Keyword.get(updates, :name, name)
    meta = Keyword.get(updates, :meta, meta)
    args = Keyword.get(updates, :args, args)

    {{:., meta, [{:__aliases__, meta1, module}, name]}, meta2, args}
  end

  @doc """
  Returns a `mfa`-tuple for the given `.`-call.
  """
  @spec mfa({{:., keyword(), list()}, Macro.metadata(), Macro.t()}) ::
          {module(), atom(), non_neg_integer()}
  def mfa({{:., _meta1, [{:__aliases__, _meta2, aliases}, fun]}, _meta3, args}) do
    {Module.concat(aliases), fun, length(args)}
  end

  @doc """
  Puts the given value `newlines` under the key `nevlines` in
  `meta[:end_of_expression]`.
  """
  @spec put_newlines({term(), Macro.metadata(), Macro.t()}, integer()) ::
          {term(), keyword(), list()}
  def put_newlines({name, meta, args}, newlines) do
    meta =
      Keyword.update(meta, :end_of_expression, [newlines: newlines], fn end_of_expression ->
        Keyword.put(end_of_expression, :newlines, newlines)
      end)

    {name, meta, args}
  end

  @doc """
  Returns the `newlines` value from `meta[:end_of_expression]`, or `nil`.
  """
  @spec get_newlines(Macro.t()) :: integer()
  def get_newlines({_name, meta, _args}) do
    case Keyword.fetch(meta, :end_of_expression) do
      {:ok, end_of_expression} -> Keyword.get(end_of_expression, :newlines)
      :error -> nil
    end
  end

  @doc """
  Returns the infos from an AST representing an `alias` expression.

  The function returns 3-tuple containing the alias, the multi part and the
  `:as`.

  ## Examples

      iex> ast = quote do
      ...>   alias Foo.Bar
      ...> end
      iex> alias_info(ast)
      {Foo.Bar, [], nil}

      iex> ast = quote do
      ...>   alias Foo.{Bar, Baz}
      ...> end
      iex> alias_info(ast)
      {Foo, [Bar, Baz], nil}

      iex> ast = quote do
      ...>   alias Foo, as: Baz
      ...> end
      iex> alias_info(ast)
      {Foo, [], Baz}
  """
  @spec alias_info(Macro.t()) :: {module(), [module()], module() | nil}
  def alias_info({:alias, _meta1, [{:__aliases__, _meta2, aliases}]}) do
    module = Module.concat(aliases)
    {module, [], nil}
  end

  def alias_info({:alias, _meta, [{{:., _meta2, [aliases, _opts]}, _meta3, multi}]}) do
    module = aliases_concat(aliases)
    multi = Enum.map(multi, &aliases_concat/1)

    {module, multi, nil}
  end

  def alias_info({:alias, _meta1, [{:__aliases__, _meta2, aliases}, [{_block, as}]]}) do
    module = Module.concat(aliases)
    as = aliases_concat(as)
    {module, [], as}
  end

  @doc """
  Concatinates the aliases of an `:__aliases__` tuple.

  ## Examples

      iex> aliases_concat({:__aliases__, [], [:Alpha, :Bravo]})
      Alpha.Bravo
  """
  @spec aliases_concat({:__aliases__, Macro.metadata(), [atom()]}) :: module()
  def aliases_concat({:__aliases__, _meta, aliases}) do
    Module.concat(aliases)
  end

  @doc """
  Converts AST representing a name to a string.

  This function suppresses the prefix `"Elixir."`.

  ## Examples

      iex> name([Recode, AST])
      "Recode.AST"

      iex> name(Recode.AST)
      "Recode.AST"
  """
  @spec name(atom() | [atom()]) :: String.t()
  def name(aliases) when is_list(aliases) do
    Enum.map_join(aliases, ".", &name/1)
  end

  def name(atom) when is_atom(atom) do
    with "Elixir." <> name <- to_string(atom) do
      name
    end
  end

  @doc """
  Returns the value from a `:__block__` with a single argument.

  ## Examples

      iex> "[1, 2]"
      ...> |> Sourceror.parse_string!()
      ...> |> get_value()
      ...> |> Enum.map(&get_value/1)
      [1, 2]
  """
  @spec get_value({:__block__, Recode.meta(), [term()]}) :: term
  def get_value({:__block__, _meta, [value]}), do: value

  @doc """
  Puts the given `value` in the `:__block__` AST.

  ## Examples

      iex> "[1, 2]"
      ...> |> Sourceror.parse_string!()
      ...> |> get_value()
      ...> |> Enum.map(fn ast -> put_value(ast, "0") end)
      ...> |> Enum.map(&get_value/1)
      ["0", "0"]
  """
  @spec put_value({:__block__, Recode.meta(), [term()]}, term()) ::
          {:__block__, Recode.meta(), [term()]}
  def put_value({:__block__, meta, [_value]}, value), do: {:__block__, meta, [value]}

  @doc """
  Updates the function name of a capture.
  """
  @spec update_capture(Macro.t(), name: atom()) :: Macro.t()
  def update_capture(
        {:&, meta1, [{:/, meta2, [{_name, meta3, nil}, {:__block__, meta4, [arity]}]}]},
        name: name
      ) do
    {:&, meta1, [{:/, meta2, [{name, meta3, nil}, {:__block__, meta4, [arity]}]}]}
  end

  def update_capture(
        {:&, meta1,
         [
           {:/, meta2,
            [
              {{:., meta3, [{:__aliases__, meta4, alias}, _name]}, meta5, []},
              {:__block__, meta6, [arity]}
            ]}
         ]},
        name: name
      ) do
    {:&, meta1,
     [
       {:/, meta2,
        [
          {{:., meta3, [{:__aliases__, meta4, alias}, name]}, meta5, []},
          {:__block__, meta6, [arity]}
        ]}
     ]}
  end
end
