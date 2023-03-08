defmodule Recode.CodeMod.DebugInfo do
  alias Sourceror.Zipper, as: Z

  defmodule Call do
    defstruct [:module, :func, :line]

    def new(module, func, line) do
      struct!(Call, module: module, func: func, line: line)
    end
  end

  def calls(%{path: path}) do
    debug_infos =
      path
      |> Code.compile_file()
      |> Enum.map(fn {_module, b} -> BeamFile.debug_info(b) end)
      |> then(&for {:ok, debug_info} <- &1, do: debug_info)

    for debug_info <- debug_infos,
        definition <- debug_info.definitions do
      {{_fun, _arity}, _def, _, block} = definition
      search_calls_in(block)
    end
    |> List.flatten()
    |> Enum.reverse()
  end

  defp search_calls_in(block) do
    # Same arity functions are grouped together as a block list
    for {_line, _args, _, body} <- Enum.reverse(block) do
      body
      |> Z.zip()
      |> Z.traverse([], fn z, calls ->
        do_search(z, calls)
      end)
      |> elem(1)
    end
  end

  defp do_search(
         {{:&, [line: line], [{:/, [], [{{:., [], [module, func]}, [], []}, _anonymous_number]}]},
          _} = zipper,
         calls
       ) do
    call = Call.new(module, func, line)
    {zipper, [call | calls]}
  end

  defp do_search({{:., [generated: true, line: line], [module, func]}, _} = zipper, calls) do
    # [generated: true, line: 1] in the case of testing: `assert baz(1)`
    call = Call.new(module, func, line)
    {zipper, [call | calls]}
  end

  defp do_search({{:., [line: line], [module, func]}, _} = zipper, calls) do
    call = Call.new(module, func, line)
    {zipper, [call | calls]}
  end

  defp do_search({{func_name, [line: line], _self_func_args}, _} = zipper, calls)
       when is_atom(func_name) do
    call = Call.new(nil, func_name, line)
    {zipper, [call | calls]}
  end

  defp do_search(zipper, calls) do
    {zipper, calls}
  end
end
