defmodule Recode.CodeMod.References do
  alias Sourceror.Zipper, as: Z

  @type position :: %{
          line: non_neg_integer(),
          column: non_neg_integer()
        }

  @type range :: %{
          start: position(),
          end: position()
        }

  @type t :: %__MODULE__{
          mfa: mfa(),
          range: range(),
          debug_line: non_neg_integer()
        }

  defstruct [:mfa, :range, :debug_line]

  def search_references(source, calls) do
    # TODO: modify the input to a flatten project modules
    module_map = project_module_map(source.modules)

    init_calls =
      calls
      |> Enum.filter(fn %{module: module} -> Map.get(module_map, module) end)

    {_z, {[], refs}} =
      source.ast
      |> Z.zip()
      |> Z.traverse({init_calls, []}, fn z, {calls, refs} ->
        search(z, {calls, refs})
      end)

    refs
  end

  defp search({{func, meta, args}, _path} = z, {calls, refs}) do
    meta_map = Map.new(meta)
    # args = if Keyword.keyword?(args), do: Map.new(args), else: args
    match(func, %{meta: meta_map, args: args}, {calls, refs}, z)
  end

  defp search(z, {[call] = calls, refs}) do
    # sometimes we can't find the func by the line number and func name at the end
    if is_nil(Z.next(z)) do
      ref = not_found(call)
      {z, {[], [ref | refs]}}
    else
      {z, {calls, refs}}
    end
  end

  defp search(z, {calls, refs}) do
    {z, {calls, refs}}
  end

  # match the original function call: like `baz() | baz(1)`
  defp match(
         func,
         %{meta: %{line: line} = meta},
         {[%{line: line, func: func} = call | rest], refs},
         z
       ) do
    range = %{
      start: %{line: line, column: meta.column},
      end: %{line: line, column: meta.column + func_length(call.func)}
    }

    ref = %__MODULE__{mfa: to_mfa(call), range: range, debug_line: line}
    {z, {rest, [ref | refs]}}
  end

  # match the function call in alias: like `&Rename.Bar.baz/1`
  defp match(
         :.,
         %{meta: %{line: line} = meta, args: [_module_aliases, func]},
         {[%{func: func, line: line} = call | rest], refs},
         z
       ) do
    range = %{
      start: %{line: line, column: meta.column + 1},
      end: %{line: line, column: meta.column + 1 + func_length(call.func)}
    }

    ref = %__MODULE__{mfa: to_mfa(call), range: range, debug_line: line}
    {z, {rest, [ref | refs]}}
  end

  defp match(_, %{meta: %{line: crossed_line}}, {[%{line: line} | rest], refs}, z)
       when crossed_line > line do
    {z, {rest, refs}}
  end

  defp match(_, _meta, {calls, refs}, z), do: {z, {calls, refs}}

  defp not_found(call) do
    range = nil
    %__MODULE__{mfa: to_mfa(call), range: range, debug_line: call.line}
  end

  defp project_module_map(modules) do
    Map.new(modules, fn module -> {module, true} end)
  end

  defp func_length(atom) do
    atom |> to_string() |> String.length()
  end

  defp to_mfa(call) do
    {call.module, call.func, call.arity}
  end
end
