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

  @type acc :: any()

  @typedoc """
  Abstract Syntax Tree (AST)
  """
  @type t ::
          atom
          | number
          | binary
          | [t()]
          | {t(), t()}
          | expr

  @typedoc """
  The metadata of an expression in the AST.
  """
  @type metadata :: keyword

  @typedoc """
  An expression in the AST.
  """
  @type expr :: {atom | expr, metadata, atom | [t()]}

  @doc """
  Returns `true` if the given AST represents an atom.

  ## Examples

      iex> ":atom" |> Code.string_to_quoted!() |> atom?()
      true

      iex> ast = Sourceror.parse_string!(":atom")
      {:__block__, [trailing_comments: [], leading_comments: [], line: 1, column: 1], [:atom]}
      ...> atom?(ast)
      true

      iex> "42" |> Sourceror.parse_string!() |> atom?()
      false

      iex> ast = Code.string_to_quoted!(
      ...>   ":a", literal_encoder: &{:ok, {:__block__, &2, [&1]}})
      {:__block__, [line: 1], [:a]}
      iex> atom?(ast)
      true
  """
  @spec atom?(t()) :: boolean()
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

  @doc ~S'''
  Returns `true` when the given `ast` expression represents an expression that
  spans over multiple lines.

  `multiline?` does not pay attention to do blocks.

  ## Examples

      iex> """
      ...> def foo(x)
      ...>     when is_integer(x) do
      ...>   {:foo, x}
      ...> end
      ...> """
      ...> |> Sourceror.parse_string!()
      ...> |> multiline?()
      true

      iex> """
      ...> def foo(x) when is_integer(x) do
      ...>   {:foo, x}
      ...> end
      ...> """
      ...> |> Sourceror.parse_string!()
      ...> |> multiline?()
      false

      iex> """
      ...> {
      ...>   x,
      ...>   y
      ...> }
      ...> """
      ...> |> Sourceror.parse_string!()
      ...> |> multiline?()
      true

      iex> """
      ...> {x, y}
      ...> """
      ...> |> Sourceror.parse_string!()
      ...> |> multiline?()
      false
  '''
  @spec multiline?(t() | metadata()) :: boolean()
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

  @doc ~S'''
  Forces a one line AST expression from a multiline AST expression.

  ## Example

      iex> """
      ...> x &&
      ...>   y
      ...> """
      ...> |> Sourceror.parse_string!()
      ...> |> to_same_line()
      ...> |> Sourceror.to_string()
      "x && y"

      iex> """
      ...> def foo,
      ...>   do:
      ...>     :foo
      ...> """
      ...> |> Sourceror.parse_string!()
      ...> |> to_same_line()
      ...> |> Sourceror.to_string()
      """
      def foo,
        do: :foo\
      """
  '''
  @spec to_same_line(t()) :: t()
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
      %Zipper{node: {expr, meta, args}} = zipper ->
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
  Returns the first line in which the given AST starts.

  > ### Note {: .info}
  >
  > The AST must be constructed by `Sourceror` or with the `Code` module and
  > the options `columns: true, token_metadata: true,
  > literal_encoder: &{:ok, {:__block__, &2, [&1]}}`.

  ## Examples

      iex> code = """
      ...> 1 +
      ...>   2 -
      ...>   3
      ...> """
      ...>
      ...> ast = Sourceror.parse_string(code)
      ...> first_line(ast)
      1
      iex> last_line(ast)
      3
      iex> code
      ...> |> Code.string_to_quoted!(
      ...>   columns: true,
      ...>   token_metadata: true,
      ...>   literal_encoder: &{:ok, {:__block__, &2, [&1]}})
      ...> |> last_line()
      3
  '''
  @spec first_line(t()) :: integer | nil
  def first_line(ast), do: get_line_by(ast, &min/2)

  @doc """
  Returns the last line in which the given AST ends.

  See `first_line/1` for example and note.
  """
  @spec last_line(t()) :: integer | nil
  def last_line(ast), do: get_line_by(ast, &max/2)

  defp get_line_by(ast, fun) do
    ast
    |> Zipper.zip()
    |> Zipper.traverse_while(nil, fn
      %Zipper{node: {_name, meta, _args}} = zipper, acc ->
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
  @spec update_definition(t(), updates :: keyword()) :: t()
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
  @spec update_spec(t(), updates :: keyword()) :: t()
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
  @spec update_call(t(), updates :: keyword()) :: t()
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
  @spec update_dot_call(t(), updates :: keyword()) :: t()
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

  A `mfa`-tuple is a three-element tuple containing the module, function name,
  and arity.

  ## Examples

      iex> ast = quote do
      ...>   Foo.Bar.baz(x)
      ...> end
      ...> mfa(ast)
      {Foo.Bar, :baz, 1}
  """
  @spec mfa({{:., metadata(), list()}, metadata(), t()}) ::
          {module(), atom(), non_neg_integer()}
  def mfa({{:., _meta1, [{:__aliases__, _meta2, aliases}, fun]}, _meta3, args}) do
    {Module.concat(aliases), fun, length(args)}
  end

  @doc """
  Returns a `mf`-tuple for the given `.`-call or `.`-expression.

  A `mf`-tuple is a two-element tuple containing the module and function name.

  ## Examples

      iex> ast = quote do
      ...>   Foo.Bar.baz(x)
      ...> end
      ...> mf(ast)
      {Foo.Bar, :baz}
      iex> {ast, _, _} = ast
      ...> mf(ast)
      {Foo.Bar, :baz}
  """
  @spec mfa({{:., metadata(), list()}, metadata(), t()} | {:., metadata(), list()}) ::
          {module(), atom()}
  def mf({{:., _meta1, [{:__aliases__, _meta2, aliases}, fun]}, _meta3, _args3}) do
    {Module.concat(aliases), fun}
  end

  def mf({:., _meta1, [{:__aliases__, _meta2, aliases}, fun]}) do
    {Module.concat(aliases), fun}
  end

  @doc """
  Puts the given value `newlines` under the key `nevlines` in
  `meta[:end_of_expression]`.
  """
  @spec put_newlines({term(), metadata(), t()}, integer()) ::
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
  @spec get_newlines(t()) :: integer()
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

      iex> ast = Sourceror.parse_string!("alias __MODULE__")
      iex> alias_info(ast)
      {:__MODULE__, [], nil}

      iex> ast = Sourceror.parse_string!("alias __MODULE__.{Foo, Bar.Baz}")
      iex> alias_info(ast)
      {:__MODULE__, [Foo, Bar.Baz], nil}

      iex> ast = Sourceror.parse_string!("alias __MODULE__, as: MyModule")
      iex> alias_info(ast)
      {:__MODULE__, [], MyModule}
  """
  @spec alias_info(t()) :: {module(), [module()], module() | nil}
  def alias_info({:alias, _meta1, [{:__aliases__, _meta2, aliases}]}) do
    aliases =
      Enum.map(aliases, fn
        {:__MODULE__, _meta, _args} -> :__MODULE__
        alias -> alias
      end)

    module = Module.concat(aliases)
    {module, [], nil}
  end

  def alias_info({:alias, _meta1, [{:__MODULE__, _meta2, nil}]}) do
    {:__MODULE__, [], nil}
  end

  def alias_info(
        {:alias, _meta1, [{{:., _meta2, [{:__MODULE__, _meta3, _args}, _opts]}, _meta4, multi}]}
      ) do
    multi = Enum.map(multi, &aliases_concat/1)

    {:__MODULE__, multi, nil}
  end

  def alias_info({:alias, _meta1, [{:__MODULE__, _meta2, _args}, [{_block, as}]]}) do
    as = aliases_concat(as)
    {:__MODULE__, [], as}
  end

  def alias_info({:alias, _meta1, [{{:., _meta2, [aliases, _opts]}, _meta3, multi}]}) do
    module = aliases_concat(aliases)
    multi = Enum.map(multi, &aliases_concat/1)

    {module, multi, nil}
  end

  def alias_info({:alias, _meta1, [{:__aliases__, _meta2, aliases}, [{_block, as}]]}) do
    module = Module.concat(aliases)
    as = aliases_concat(as)
    {module, [], as}
  end

  def alias_info({:alias, _meta1, [{:__block__, _meta2, aliases}, [{_block, as}]]}) do
    module = Module.concat(aliases)
    as = aliases_concat(as)
    {module, [], as}
  end

  def alias_info({:alias, _meta1, [{:unquote, _meta2, _args}]}) do
    {nil, [], nil}
  end

  def alias_info({:alias, _meta1, [{:unquote, _meta2, _args}, [{_block, as}]]}) do
    {nil, [], as}
  end

  @doc """
  Concatinates the aliases of an `:__aliases__` tuple.

  ## Examples

      iex> aliases_concat({:__aliases__, [], [:Alpha, :Bravo]})
      Alpha.Bravo
  """
  @spec aliases_concat({:__aliases__, metadata(), [atom()]} | list) :: module()
  def aliases_concat({:__aliases__, _meta, aliases}) do
    Module.concat(aliases)
  end

  def aliases_concat([{:__aliases__, _meta, aliases} | _]) do
    Module.concat(aliases)
  end

  @doc """
  Returns the module name as an atom for the given `ast`.

  The function accepts `{:defmodule, meta, args}`, the `args` form the
  `:defmodule` tuple or the same input as `aliases_concat/1`.
  """
  @spec module(t()) :: module
  def module(ast)
  def module({:defmodule, _metag, [arg | _args]}), do: aliases_concat(arg)
  def module(args), do: aliases_concat(args)

  @doc """
  Converts AST representing a name to a string.

  This function suppresses the prefix `"Elixir."`.

  ## Examples

      iex> name([Recode, Task])
      "Recode.Task"

      iex> name(Recode.Task)
      "Recode.Task"
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

  @doc ~S'''
  Returns the `:do` or `:else` block arguments of the given `expr`.

  ## Examples

      iex> ast = Sourceror.parse_string!("""
      ...> defmodule Foo do
      ...>   def bar, do: bar
      ...> end
      ...> """)
      ...> block = block(ast)
      ...> Sourceror.to_string({:__block__,[], block})
      "def bar, do: bar"

      iex> {:defmodule, _meta, [_aliases, args]} = Sourceror.parse_string!("""
      ...> defmodule Foo do
      ...>   def bar, do: bar
      ...>   def baz, do: baz
      ...> end
      ...> """)
      ...> block = block(args)
      ...> Sourceror.to_string({:__block__,[], block})
      """
      def bar, do: bar
      def baz, do: baz\
      """

      iex> ast = Sourceror.parse_string!("""
      ...> if x, do: true, else: false
      ...> """)
      ...> block(ast, :else)
      [false]
      ...> block(ast)
      [true]
      ...> block(ast, :do)
      [true]

      iex> ast = Sourceror.parse_string!("x == y")
      ...> block(ast)
      nil
  '''
  @spec block(expr(), :do | :else) :: t()
  def block(expr, key \\ :do)

  def block({_form, _meta, args}, key) when key in [:do, :else] do
    do_block(args, key, 0)
  end

  def block(args, key) when is_list(args) and key in [:do, :else] do
    do_block(args, key, 0)
    # Enum.find_value(args, fn arg -> do_block(arg, key) end)
  end

  defp do_block(list, key, depth) when is_list(list) and depth <= 1 do
    Enum.find_value(list, fn
      {{:__block__, _meta_key, [^key]}, {:__block__, _meta_block, block}} -> block
      {{:__block__, _meta_key, [^key]}, block} -> [block]
      list when is_list(list) -> do_block(list, key, depth + 1)
      _item -> false
    end)
  end

  defp do_block(_list, _key, _depth), do: false

  @doc """
  Returns the value from a `:__block__` with a single argument.

  ## Examples

      iex> "[1, 2]"
      ...> |> Sourceror.parse_string!()
      ...> |> get_value()
      ...> |> Enum.map(&get_value/1)
      [1, 2]
  """
  @spec get_value(t()) :: term
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
  @spec put_value(t(), term()) :: t()
  def put_value({:__block__, meta, [_value]}, value), do: {:__block__, meta, [value]}

  @doc """
  Updates the function name of a capture.
  """
  @spec update_capture(t(), name: atom()) :: t()
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

  @doc """
  Performs a depth-first, pre-order traversal of quoted expressions and invokes
  `fun` for each node in the `ast` with the accumulator `acc`.

  The initial value of the accumulator is `acc`. The function is invoked for each
  node in the `ast` with the accumulator. The result returned by the function is
  used as the accumulator for the next iteration. The function returns the last
  accumulator.

  ## Examples

      iex> ast = quote do
      ...>   def foo(x), {:oof, x}
      ...>   def bar(x), {:rab, x}
      ...> end
      ...> AST.reduce(ast, [], fn
      ...>   {:def, _, [{name, _, _}|_]}, acc -> [name | acc]
      ...>   ast, acc when is_atom(ast) -> [ast|acc]
      ...>   _ast, acc -> acc
      ...> end)
      [:rab, :bar, :oof, :foo]
  """
  @spec reduce(t(), acc(), (t(), acc() -> acc())) :: acc()
  def reduce(ast, acc, fun) do
    acc
    |> do_reduce_apply(ast, fun)
    |> do_reduce(ast, fun)
  end

  defp do_reduce(acc, {form, _meta, args}, fun) when is_atom(form) do
    do_reduce_args(acc, args, fun)
  end

  defp do_reduce(acc, {form, _meta, args}, fun) do
    acc
    |> do_reduce_apply(form, fun)
    |> do_reduce(form, fun)
    |> do_reduce_args(args, fun)
  end

  defp do_reduce(acc, {left, right}, fun) do
    acc
    |> do_reduce_apply(left, fun)
    |> do_reduce(left, fun)
    |> do_reduce_apply(right, fun)
    |> do_reduce(right, fun)
  end

  defp do_reduce(acc, ast, fun) when is_list(ast) do
    do_reduce_args(acc, ast, fun)
  end

  defp do_reduce(acc, _ast, _fun), do: acc

  defp do_reduce_args(acc, [], _fun), do: acc

  defp do_reduce_args(acc, [arg | args], fun) do
    acc
    |> do_reduce_apply(arg, fun)
    |> do_reduce(arg, fun)
    |> do_reduce_args(args, fun)
  end

  defp do_reduce_args(acc, _arg, _fun), do: acc

  @compile {:inline, do_reduce_apply: 3}
  defp do_reduce_apply(acc, ast, fun), do: fun.(ast, acc)

  @doc """
  Reduces the `ast` until `fun` returns `{:halt, term}`.

  The return value for `fun` is expected to be

    * `{:cont, acc}` to continue the reduction with the next node in the ast and
       `acc` as the new accumulator

    * `{:skip, acc}` to continue the reduction while skippin the childrens of
       current node and `acc` as the new accumulator

    * `{:halt, acc}` to halt the reduction or

  If `fun` returns `{:halt, acc}` the reduction is halted and the function
  returns `acc`. Otherwise, if the AST is exhausted, the function returns the
  accumulator of the last `{:cont, acc}`.

  ## Examples

      iex> ast = quote do
      ...>   def foo(x), {:oof, x}
      ...>   def bar(x, y), {:rab, x, y}
      ...> end
      ...>
      ...> AST.reduce_while(ast, [], fn
      ...>   {:def, _, [{name, _, args}|_]}, acc
      ...>     -> acc = [name | acc]
      ...>        if length(args) == 1 do
      ...>          {:cont, acc}
      ...>        else
      ...>          {:skip, acc}
      ...>        end
      ...>   ast, acc when is_atom(ast)
      ...>     -> {:cont, [ast|acc]}
      ...>   _ast, acc
      ...>     -> {:cont, acc}
      ...> end)
      [:bar, :oof, :foo]
  """
  @spec reduce_while(t(), acc(), (t(), acc() -> result)) :: acc()
        when result: {:cont, acc()} | {:halt, acc()} | {:skip, acc()}
  def reduce_while(ast, acc, fun) do
    acc
    |> do_reduce_while_apply(ast, fun)
    |> do_reduce_while(ast, fun)
    |> elem(1)
  end

  defp do_reduce_while({:cont, acc}, {form, _meta, args}, fun) when is_atom(form) do
    do_reduce_while_args(acc, args, fun)
  end

  defp do_reduce_while({:cont, acc}, {form, _meta, args}, fun) do
    acc
    |> do_reduce_while_apply(form, fun)
    |> do_reduce_while(form, fun)
    |> elem(1)
    |> do_reduce_while_args(args, fun)
  end

  defp do_reduce_while({:cont, acc}, {left, right}, fun) do
    acc
    |> do_reduce_while_apply(left, fun)
    |> do_reduce_while(left, fun)
    |> elem(1)
    |> do_reduce_while_apply(right, fun)
    |> do_reduce_while(right, fun)
  end

  defp do_reduce_while({_tag, acc}, ast, fun) when is_list(ast) do
    do_reduce_while_args(acc, ast, fun)
  end

  defp do_reduce_while({:skip, acc}, _ast, _fun), do: {:cont, acc}
  defp do_reduce_while(acc, _ast, _fun), do: acc

  defp do_reduce_while_args(acc, [], _fun), do: {:cont, acc}

  defp do_reduce_while_args(acc, [arg | args], fun) do
    acc
    |> do_reduce_while_apply(arg, fun)
    |> do_reduce_while(arg, fun)
    |> elem(1)
    |> do_reduce_while_args(args, fun)
  end

  defp do_reduce_while_args(acc, _arg, _fun), do: {:cont, acc}

  @compile {:inline, do_reduce_while_apply: 3}
  defp do_reduce_while_apply(acc, ast, fun) do
    case fun.(ast, acc) do
      {tag, _data} = acc when tag in [:cont, :halt, :skip] -> acc
    end
  end
end
