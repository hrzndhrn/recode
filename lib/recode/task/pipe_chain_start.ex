defmodule Recode.Task.PipeChainStart do
  @shortdoc "Checks if a pipe chain starts with a raw value."

  @moduledoc """
  Pipes should start with a raw value to improve readability.

      # preferred
      user
      |> User.changeset(params)
      |> Repo.insert()

      # not preferred
      User.changeset(user, params)
      |> Repo.insert()

  Starting a pipe chain with a function call instead of a raw value can make
  the code harder to follow, as the data flow is less clear.

  This task rewrites the code when `mix recode` runs with `autocorrect: true`.
  """

  use Recode.Task, corrector: true, category: :readability

  alias Recode.AST
  alias Rewrite.Source
  alias Sourceror.Zipper

  @sigils [
    :sigil_C,
    :sigil_c,
    :sigil_D,
    :sigil_N,
    :sigil_r,
    :sigil_S,
    :sigil_s,
    :sigil_T,
    :sigil_U,
    :sigil_W,
    :sigil_w
  ]

  @unary_ops [
    :!,
    :"~~~",
    :&,
    :+,
    :-,
    :@,
    :^,
    :not
  ]

  @binary_ops [
    :!=,
    :!==,
    :"//",
    :"::",
    :"<|>",
    :"^^^",
    :&&&,
    :&&,
    :**,
    :*,
    :+++,
    :++,
    :+,
    :-,
    :--,
    :---,
    :.,
    :..,
    :..//,
    :/,
    :<,
    :<-,
    :<<<,
    :<<~,
    :<=,
    :<>,
    :<~,
    :<~>,
    :=,
    :==,
    :===,
    :=~,
    :>,
    :>=,
    :>>>,
    :\\,
    :and,
    :in,
    :or,
    :when,
    :|,
    :|>,
    :||,
    :|||,
    :~>,
    :~>>
  ]

  @special_forms [
    :<<>>,
    :__block__,
    :case,
    :cond,
    :fn,
    :for,
    :if,
    :unquote,
    :unquote_splicing,
    :with
  ]

  @exclude_functions Enum.concat([@special_forms, @sigils, @unary_ops, @binary_ops])

  @impl Recode.Task
  def run(source, opts) do
    source
    |> Source.get(:quoted)
    |> Zipper.zip()
    |> Zipper.traverse([], fn zipper, issues ->
      pipe_chain_start(zipper, issues, opts[:autocorrect], opts)
    end)
    |> update(source, opts)
  end

  defp update({zipper, issues}, source, opts) do
    update_source(source, opts, quoted: zipper, issues: issues)
  end

  @impl Recode.Task
  def init(config) do
    config =
      config
      |> Keyword.put_new(:exclude_functions, [])
      |> Keyword.put_new(:exclude_arguments, [])

    {:ok, config}
  end

  # inside pipe
  defp pipe_chain_start(
         %Zipper{node: {:|>, _, [{:|>, _, _} | _]}} = zipper,
         issues,
         _autocorrect,
         _opts
       ) do
    {zipper, issues}
  end

  # pipe start
  defp pipe_chain_start(
         %Zipper{node: {:|>, meta, [lhs, rhs]}} = zipper,
         issues,
         autocorrect,
         opts
       ) do
    case check(lhs, opts) do
      :ok ->
        {zipper, issues}

      {:error, correction} when autocorrect ->
        {correct(zipper, correction, rhs), issues}

      {:error, _correction} when not autocorrect ->
        {zipper, add_issue(issues, meta)}
    end
  end

  defp pipe_chain_start(zipper, issues, _autocorrect, _opts) do
    {zipper, issues}
  end

  defp check(
         {{:., _meta1, [{:__aliases__, _meta2, _aliases2}, _fun]} = form, meta, [arg | rest]},
         opts
       ) do
    mf = AST.mf(form)

    with :error <- check(mf, meta, arg, opts) do
      correction(arg, form, rest)
    end
  end

  defp check({{:., _meta1, [Access, :get]}, _meta, _args}, _opts) do
    :ok
  end

  defp check({{:., _meta1, [_arg1 | _rest1]} = form, meta, [arg | rest]}, opts) do
    with :error <- check(:., meta, arg, opts) do
      correction(arg, form, rest)
    end
  end

  defp check({form, meta, [arg | rest]}, opts)
       when is_atom(form) and form not in @exclude_functions do
    with :error <- check(form, meta, arg, opts) do
      correction(arg, form, rest)
    end
  end

  defp check(_ast, _opts), do: :ok

  defp check(form, meta, arg, opts) do
    with :error <- exclude_function(form, opts[:exclude_functions]),
         :error <- exclude_argument(arg, opts[:exclude_arguments]) do
      custom_sigil(form, meta[:delimiter])
    end
  end

  defp correction(arg, form, rest) do
    {:error, {:|>, [], [arg, {form, [], rest}]}}
  end

  defp custom_sigil(_atom, nil), do: :error

  defp custom_sigil(atom, _delimeter) do
    sigil? = atom |> to_string() |> String.starts_with?("sigil_")

    if sigil?, do: :ok, else: :error
  end

  defp correct(zipper, lhs, rhs) do
    Zipper.replace(zipper, {:|>, [], [lhs, rhs]})
  end

  defp add_issue(issues, meta) do
    message = "Pipe chain should start with a raw value."
    [new_issue(message, meta) | issues]
  end

  defp exclude_function(_fun, []), do: :error

  defp exclude_function({module, fun}, exclude) do
    if {module, fun} in exclude or {module, :*} in exclude, do: :ok, else: :error
  end

  defp exclude_function(fun, exclude) do
    if fun in exclude, do: :ok, else: :error
  end

  defp exclude_argument({:__block__, _meta, [literal]}, _include)
       when is_atom(literal) or is_number(literal) or is_binary(literal) or is_list(literal) do
    :error
  end

  defp exclude_argument({form, _meta, nil}, _include) when is_atom(form) do
    :error
  end

  defp exclude_argument({{:., _meta1, _args1}, _meta2, _args2}, _include) do
    :error
  end

  defp exclude_argument({form, _meta, _}, exclude) do
    if form in exclude, do: :ok, else: :error
  end

  defp exclude_argument(_arg, _include), do: :ok
end
