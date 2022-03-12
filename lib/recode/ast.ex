defmodule Recode.AST do
  @moduledoc """
  TODO: @moduledoc
  """

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

  def update_call({name, meta, args}, updates) do
    name = Keyword.get(updates, :name, name)
    meta = Keyword.get(updates, :meta, meta)
    args = Keyword.get(updates, :args, args)

    {name, meta, args}
  end

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
