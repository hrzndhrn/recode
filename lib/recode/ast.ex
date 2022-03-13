defmodule Recode.AST do
  @moduledoc """
  This module provides functions to manipulate the AST.
  """

  @doc """
  Updates the AST representing a definition.

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
  Update a function call.

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

  def mfa({{:., _meta1, [{:__aliases__, _meta2, aliases}, fun]}, _meta3, args}) do
    {Module.concat(aliases), fun, length(args)}
  end
end
