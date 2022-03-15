defmodule Recode.Task.Rename do
  @moduledoc """
  A refactoring task to rename functions.

  For usage, see `mix recode.rename`.
  """

  use Recode.Task, refactor: true

  import Kernel, except: [match?: 2]

  alias Recode.AST
  alias Recode.Context
  alias Recode.DebugInfo
  alias Recode.Project
  alias Recode.Source
  alias Recode.Task.Rename
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(project, opts) do
    Project.map(project, fn source ->
      zipper =
        source
        |> Source.zipper!()
        |> Context.traverse(fn zipper, context ->
          opts = Keyword.put(opts, :source, source)
          rename(zipper, context, opts)
        end)

      source = Source.update(source, Rename, code: zipper)

      {:ok, source}
    end)
  end

  defp rename({{fun, _meta, [call, _expr]}, _zipper_meta} = zipper, context, opts)
       when fun in [
              :def,
              :defp,
              :defmacro,
              :defmacrop
            ] do
    case rename?(:definition, call, context, opts[:from]) do
      true ->
        zipper = zipper |> update_definition(opts[:to]) |> Zipper.next()
        {zipper, context}

      false ->
        zipper = Zipper.next(zipper)
        {zipper, context}
    end
  end

  defp rename({{fun, _meta, _args}, _zipper_meta} = zipper, context, _opts)
       when fun in [
              :alias,
              :defmodule,
              :defdelegate,
              :__aliases__,
              :__block__
            ] do
    {zipper, context}
  end

  defp rename({{fun, _meta, _args} = ast, _zipper_meta} = zipper, context, opts)
       when is_atom(fun) do
    case rename?(:call, ast, context, opts) do
      false ->
        {zipper, context}

      true ->
        zipper = update_call(zipper, opts[:to])

        {zipper, context}
    end
  end

  defp rename(
         {{{:., _meta1, [{:__aliases__, _meta2, _args2}, _fun]}, _meta3, _args3} = ast,
          _zipper_meta} = zipper,
         context,
         opts
       ) do
    case rename?(:dot, ast, context, opts) do
      false ->
        {zipper, context}

      true ->
        zipper = update_dot_call(zipper, opts[:to])

        {zipper, context}
    end
  end

  defp rename(zipper, context, _opts) do
    {zipper, context}
  end

  defp rename?(
         :definition,
         {fun, _meta1, args},
         %Context{module: {module, _meta2}},
         {module, fun, arity}
       ) do
    arity?(args, arity)
  end

  defp rename?(
         :definition,
         {:when, _meta1, [{fun, _meta2, args}, _when]},
         %Context{module: {module, _meta3}},
         {module, fun, arity}
       ) do
    arity?(args, arity)
  end

  defp rename?(:definition, _ast, _context, _from) do
    false
  end

  defp rename?(:call, {fun, _meta, args}, context, opts) when not is_nil(args) do
    from = opts[:from]

    with true <- fun == elem(from, 1) do
      mfa = {nil, fun, length(args)}
      rename?(:debug, mfa, context, opts)
    end
  end

  defp rename?(:call, _ast, _context, _from) do
    false
  end

  defp rename?(:dot, ast, context, opts) do
    mfa = AST.mfa(ast)
    from = opts[:from]

    with true <- fun?(mfa, from) do
      case Context.expand_mfa(context, mfa) do
        {:ok, mfa} ->
          match?(mfa, from)

        :error ->
          rename?(:debug, mfa, context, opts)
      end
    end
  end

  defp rename?(:debug, mfa, context, opts) do
    source = opts[:source]

    case Source.debug_info(source, Context.module(context)) do
      {:error, _reason} ->
        false

      {:ok, debug_info} ->
        case DebugInfo.expand_mfa(debug_info, context, mfa) do
          {:ok, mfa} -> match?(mfa, opts[:from])
          :error -> false
        end
    end
  end

  defp arity?(args, arity) do
    cond do
      is_nil(arity) -> true
      is_nil(args) -> arity == 0
      true -> length(args) == arity
    end
  end

  defp fun?({_module1, fun, _arity1}, {_module2, fun, _arity2}), do: true

  defp fun?(_mfa1, _mfa2), do: false

  defp match?({module, fun, arity}, {module, fun, arity}), do: true

  defp match?({module, fun, _arity}, {module, fun, nil}), do: true

  defp match?(_mfa1, _mfa2), do: false

  defp update_definition({ast, _meta} = zipper, %{fun: name}) do
    ast = AST.update_definition(ast, name: name)
    Zipper.replace(zipper, ast)
  end

  defp update_call({ast, _meta} = zipper, %{fun: name}) do
    ast = AST.update_call(ast, name: name)
    Zipper.replace(zipper, ast)
  end

  defp update_dot_call({ast, _meta} = zipper, %{fun: name}) do
    ast = AST.update_dot_call(ast, name: name)
    Zipper.replace(zipper, ast)
  end
end
