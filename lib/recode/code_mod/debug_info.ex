defmodule Recode.CodeMod.DebugInfo do
  alias Sourceror.Zipper, as: Z

  defmodule Call do
    defstruct [:module, :func, :line, :arity]

    def new(module, func, line, arity) do
      struct!(Call, module: module, func: func, line: line, arity: arity)
    end
  end

  def calls(%{path: path}) do
    path |> Code.compile_file() |> calls()
  end

  def calls(string) when is_binary(string) do
    string |> Code.compile_string() |> calls()
  end

  def calls(compiled) do
    debug_infos =
      compiled
      |> Enum.map(fn {_module, b} -> BeamFile.debug_info(b) end)
      |> then(&for {:ok, debug_info} <- &1, do: debug_info)

    for debug_info <- debug_infos,
        definition <- sort_definitions(debug_info.definitions) do
      {{_fun, _arity}, _def, _, block} = definition
      search_calls_in(block)
    end
    |> List.flatten()
  end

  defp sort_definitions(definitions) do
    Enum.sort_by(definitions, fn {{_fun, _arity}, _def, line, _block} ->
      line[:line]
    end)
  end

  defp search_calls_in(block) do
    # Same arity functions are grouped together as a block list
    for {_line, _args, _, body} <- block do
      body
      |> Z.zip()
      |> Z.traverse([], fn z, calls ->
        do_search(z, calls)
      end)
      |> elem(1)
      |> Enum.reverse()
    end
  end

  defp do_search(
         {{:&, [line: line], [{:/, [], [{{:., [], [module, func]}, [], []}, anonymous_number]}]},
          _} = zipper,
         calls
       ) do
    call = Call.new(module, func, line, anonymous_number)
    {zipper, [call | calls]}
  end

  defp do_search({{:., [generated: true, line: line], [module, func]}, _} = zipper, calls) do
    # [generated: true, line: 1] in the case of testing: `assert baz(1)`
    parent = zipper |> Z.up() |> Z.node()
    {_node, _line, args} = parent
    call = Call.new(module, func, line, length(args))
    {zipper, [call | calls]}
  end

  defp do_search({{:., [line: line], [module, func]}, _} = zipper, calls) do
    # normal call, like: `bar(1)` or `bar() |> bar(1)` or `{bar, bar(1)}`
    # TODO: refactor to more declarative
    parent = zipper |> Z.up() |> Z.node()
    {_node, _line, args} = parent
    call = Call.new(module, func, line, length(args))

    calls =
      if nested_call?(args) or in_a_nested_call?(zipper),
        do: calls ++ [call],
        else: [call | calls]

    {zipper, calls}
  end

  defp do_search({{func_name, [line: line], self_func_args}, _} = zipper, calls)
       when is_atom(func_name) do
    call = Call.new(nil, func_name, line, self_func_args |> length())
    {zipper, [call | calls]}
  end

  defp do_search(zipper, calls) do
    {zipper, calls}
  end

  defp nested_call?([{{:., _, [_module, _func]}, _, _} | _]), do: true

  defp nested_call?(_), do: false

  defp in_a_nested_call?(zipper) do
    grandpa = zipper |> Z.up() |> Z.up()

    if is_nil(grandpa) do
      false
    else
      {grandpa_node, _line, _args} = Z.node(grandpa)
      # like bar() |> baz(), baz is the grandpa of bar
      match?({:., _, [_module, _func]}, grandpa_node)
    end
  end
end
