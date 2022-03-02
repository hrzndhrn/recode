defmodule Recode.AST do
  def get_aliases([{:__aliases__, _, path}, name]), do: {path, name}
  def get_aliases(_), do: nil

  @deprecated "obsolete?"
  def fetch_aliases(ast) do
    case get_aliases(ast) do
      nil -> :error
      dot -> {:ok, dot}
    end
  end

  @deprecated "obsolete?"
  def get_dot({{:., _meta1, aliases}, _meta2, args}) do
    case fetch_aliases(aliases) do
      :error -> nil
      {:ok, {path, name}} -> {path, name, args}
    end
  end

  @deprecated "obsolete?"
  def get_mfa({{:., _, aliases}, _, args}) do
    case fetch_aliases(aliases) do
      :error -> nil
      {:ok, {path, name}} -> {path, name, length(args)}
    end
  end

  def get_mfa(ast) do
    case fetch_function(ast) do
      :error -> nil
      {:ok, {fun, args}} -> {nil, fun, length(args)}
    end
  end

  def get_function({atom, _meta, nil}) when is_atom(atom) do
    {atom, []}
  end

  def get_function({atom, _meta, args}) when is_atom(atom) and is_list(args) do
    {atom, args}
  end

  def get_function(_), do: nil

  def fetch_function(ast) do
    case get_function(ast) do
      nil -> :error
      fun -> {:ok, fun}
    end
  end

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

  @deprecated "obsolete?"
  def update_mfa({{:., meta1, aliases}, meta2, args}, {nil, fun, nil}) do
    {{:., meta1, update_aliases(aliases, name: fun)}, meta2, args}
  end

  @deprecated "obsolete?"
  def update_aliases([{:__aliases__, meta, path}, name], opts) do
    name = Keyword.get(opts, :name, name)
    path = Keyword.get(opts, :path, path)
    [{:__aliases__, meta, path}, name]
  end

  @deprecated "obsolete?"
  def update_function({_name, meta, args}, {nil, fun, nil}) do
    {fun, meta, args}
  end

  @deprecated "obsolete?"
  def do_block?([{{:__block__, _meta, [:do]}, _block}]), do: true

  def do_block?(_ast), do: false
end
