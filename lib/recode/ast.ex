defmodule Recode.AST do
  def get_aliases([{:__aliases__, _, path}, name]), do: {path, name}
  def get_aliases(_), do: nil

  def fetch_aliases(ast) do
    case get_aliases(ast) do
      nil -> :error
      dot -> {:ok, dot}
    end
  end

  def get_dot({{:., _meta1, aliases}, _meta2, args}) do
    case fetch_aliases(aliases) do
      :error -> nil
      {:ok, {path, name}} -> {path, name, args}
    end
  end

  # TODO: rename to get_afa (afa = alias-function-arity eq. moudle-function-arity)
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

  def update_mfa({{:., meta1, aliases}, meta2, args}, {nil, fun, nil}) do
    {{:., meta1, update_aliases(aliases, name: fun)}, meta2, args}
  end

  def update_aliases([{:__aliases__, meta, path}, name], opts) do
    name = Keyword.get(opts, :name, name)
    path = Keyword.get(opts, :path, path)
    [{:__aliases__, meta, path}, name]
  end

  def update_function({_name, meta, args}, {nil, fun, nil}) do
    {fun, meta, args}
  end

  [
    {
      {:__block__,
       [
         trailing_comments: [],
         leading_comments: [],
         format: :keyword,
         line: 2,
         column: 12
       ], [:do]},
      {:__block__, [trailing_comments: [], leading_comments: [], line: 2, column: 16], [:baz]}
    }
  ]

  def do_block?([{{:__block__, _meta, [:do]}, _block}]), do: true

  def do_block?(_ast), do: false
end
