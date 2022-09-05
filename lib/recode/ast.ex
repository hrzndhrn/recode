defmodule Recode.AST do
  @moduledoc """
  This module provides functions to get informations from the AST and to
  manipulate the AST.

  Most of the functions in this module require an AST with additional
  informations. This information is provided by `Sourceror` or
  `Code.string_to_quoted/2` with the options
  ```elixir
  [
    columns: true,
    literal_encoder: &{:ok, {:__block__, &2, [&1]}},
    token_metadata: true,
    unescape: false
  ]
  ```
  See also [Formatting considerations](https://hexdocs.pm/elixir/Code.html#quoted_to_algebra/2-formatting-considerations)
  in the docs for `Code.quoted_to_algebra/2`.

  This module provides `literal?` functions that are also work with encoded
  literals generate by `literal_encoder: %{:ok, {:__block__, &2, [&1]}}`.
  For an example see `atom?/1`.
  """

  alias Sourceror.Zipper

  @doc """
  Returns `true` if the given AST represents an atom.

  ## Examples

      iex> ":atom" |> Code.string_to_quoted!() |> atom?()
      true

      iex> ":atom" |> Sourceror.parse_string!() |> atom?()
      true

      iex> "42" |> Sourceror.parse_string!() |> atom?()
      false

      iex> ast = Code.string_to_quoted!(
      ...>   ":a", literal_encoder: &{:ok, {:__block__, &2, [&1]}})
      {:__block__, [line: 1], [:a]}
      iex> atom?(ast)
      true
  """
  @spec atom?(Macro.t()) :: boolean()
  def atom?(atom) when is_atom(atom), do: true

  def atom?({:__block__, _meta, [atom]}) when is_atom(atom), do: true

  def atom?(_ast), do: false

  @operators [
    :"=>",
    :&&&,
    :&&,
    :*,
    :+,
    :-,
    :->,
    :/,
    :<-,
    :=,
    :==,
    :and,
    :in,
    :not,
    :or,
    :||,
    :|||
  ]

  def foo(x)
      when is_integer(x) do
    {:foo, x}
  end

  @doc ~S'''
  Returns `true` when the given `ast` represents an expression that spans over
  multiple lines.

  `multiline?` does not pay attention to do blocks.

  ## Examples

      iex> """
      ...> def foo(x)
      ...>     when is_integer(x) do
      ...>   {:foo, x}
      ...> end
      ...> """
      ...> |> Sourceror.parse_string!() |> multiline?()
      true

      iex> """
      ...> def foo(x) when is_integer(x) do
      ...>   {:foo, x}
      ...> end
      ...> """
      ...> |> Sourceror.parse_string!() |> multiline?()
      false

      iex> """
      ...> {
      ...>   x,
      ...>   y
      ...> }
      ...> """
      ...> |> Sourceror.parse_string!() |> multiline?()
      true

      iex> """
      ...> {x, y}
      ...> """
      ...> |> Sourceror.parse_string!() |> multiline?()
      false
  '''
  @spec multiline?(Macro.t() | Macro.metadata()) :: boolean()
  def multiline?({op, _meta, [left, right]}) when op in @operators do
    last_line(right) > first_line(left)
  end

  def multiline?({_expr, meta, _args}), do: multiline?(meta)

  def multiline?(meta) when is_list(meta) do
    case {Keyword.has_key?(meta, :closing), Keyword.has_key?(meta, :do)} do
      {true, false} -> meta[:line] < meta[:closing][:line]
      {false, true} -> meta[:line] < meta[:do][:line]
      _else -> false
    end
  end

  def to_same_line({op, _meta, [left, right]} = ast) when op in @operators do
    to_same_line(ast, first_line(left), last_line(right))
  end

  def to_same_line({_expr, meta, _args} = ast) do
    begin_line = meta[:line]

    end_line =
      case {Keyword.has_key?(meta, :closing), Keyword.has_key?(meta, :do)} do
        {true, false} -> meta[:closing][:line]
        {false, true} -> meta[:do][:line]
        _fallback -> begin_line
      end

    to_same_line(ast, begin_line, end_line)
  end

  defp to_same_line(meta, line) when is_list(meta) do
    meta =
      meta
      |> Keyword.delete(:newlines)
      |> Keyword.put(:line, line)

    cond do
      Keyword.has_key?(meta, :closing) -> Keyword.put(meta, :closing, line: line)
      Keyword.has_key?(meta, :do) -> Keyword.put(meta, :do, line: line)
      true -> meta
    end
  end

  defp to_same_line(ast, begin_line, end_line) do
    ast
    |> Zipper.zip()
    |> Zipper.traverse_while(fn
      {{expr, meta, args}, _zipper_meta} = zipper ->
        if meta[:line] >= begin_line and meta[:line] <= end_line do
          meta = to_same_line(meta, begin_line)
          {:cont, Zipper.replace(zipper, {expr, meta, args})}
        else
          {:halt, zipper}
        end

      zipper ->
        {:cont, zipper}
    end)
    |> Zipper.node()
  end

  @doc ~S'''
  Returns the line in which the given AST starts.

  Note: The AST must be constructed by `Sourceror` or with the `Code` module and
  the options `columns: true, token_metadata: true`.

  ## Examples

      iex> code = """
      ...> 1 +
      ...>   2 -
      ...>   3
      ...> """
      iex> code |> Sourceror.parse_string!() |> first_line()
      1
      iex> code |> Sourceror.parse_string!() |> last_line()
      3
      iex> code
      ...> |> Code.string_to_quoted!(
      ...>   columns: true,
      ...>   token_metadata: true,
      ...>   literal_encoder: &{:ok, {:__block__, &2, [&1]}})
      ...> |> last_line()
      3

  '''
  def first_line(ast), do: get_line_by(ast, &min/2)

  def last_line(ast), do: get_line_by(ast, &max/2)

  defp get_line_by(ast, fun) do
    ast
    |> Zipper.zip()
    |> Zipper.traverse_while(nil, fn
      {{_name, meta, _args}, _zipper_meta} = zipper, acc ->
        line = meta[:line]

        case acc do
          nil -> {:cont, zipper, line}
          _line -> {:cont, zipper, fun.(acc, line)}
        end

      zipper, acc ->
        {:cont, zipper, acc}
    end)
    |> elem(1)
  end

  @doc ~S'''
  Updates the AST representing a definition.

  The keyword list `updates` can have the keys `name`, `meta` and `args`.

  ## Examples

      iex> ast = Sourceror.parse_string!("def foo(x), do: x")
      iex> ast |> update_definition(name: :bar) |> Macro.to_string()
      "def bar(x), do: x"
      iex> ast |> update_definition(args: [{:y, [], nil}]) |> Macro.to_string()
      "def foo(y), do: x"
  '''
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

      iex> quote do
      ...>   @spec foo(integer()) :: integer()
      ...> end
      ...> |> update_spec(name: :bar, return: {:term, [], []})
      ...> |> Macro.to_string()
      "@spec bar(integer()) :: term()"
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

      iex> quote do
      ...>   foo(x)
      ...> end
      ...> |> update_call(name: :bar)
      ...> |> Macro.to_string()
      "bar(x)"
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
  @spec get_value(Macro.t()) :: term
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
  @spec put_value(Macro.t(), term()) :: Macro.t()
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
