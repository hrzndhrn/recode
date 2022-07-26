defmodule Recode.DebugInfo do
  @moduledoc """
  This module provides helper functions to work with debug info.
  """

  import Recode.Utils, only: [ends_with?: 2]

  alias Recode.Context
  alias Sourceror.Zipper

  @spec expand_mfa(map(), Context.t(), {module() | nil, atom(), non_neg_integer()}) ::
          {:ok, mfa()} | :error
  def expand_mfa(debug_info, context, {_module, fun, arity} = mfa) do
    with {:ok, definitions} <- Map.fetch(debug_info, :definitions) do
      blocks =
        case find_block(definitions, context) do
          {:ok, block} ->
            block

          :error ->
            get_blocks(definitions)
        end

      expand =
        blocks
        |> Zipper.zip()
        |> Zipper.traverse_while(nil, fn zipper, _acc ->
          do_expand_mfa(zipper, mfa)
        end)
        |> elem(1)
        |> default(Context.module(context))

      {:ok, {expand, fun, arity}}
    end
  end

  defp get_blocks(definitions) do
    Enum.map(definitions, fn {{_fun, _arity}, _kind, _meta_fun, blocks} ->
      case blocks do
        [{_meta, _fun, _opts, {:__block__, _meta_block, blocks}}] -> blocks
        [{_meta, _fun, _opts, blocks}] -> [blocks]
        _else -> blocks
      end
    end)
  end

  defp default(nil, default), do: default

  defp default(value, _default), do: value

  defp find_block(definitions, context) do
    Enum.find_value(
      definitions,
      :error,
      fn definition -> do_find_block(definition, context) end
    )
  end

  defp do_find_block(
         {{fun, arity}, kind, _meta_fun, blocks},
         %Context{definition: {{kind, fun, arity}, meta_def}}
       ) do
    Enum.find_value(blocks, fn {meta, _args, _opts, block} ->
      with true <- meta[:line] == meta_def[:line] do
        {:ok, [block]}
      end
    end)
  end

  defp do_find_block(
         {{_fun, _arity}, _kind, _meta_fun, blocks},
         %Context{node: {_fun_node, meta_node, _args}}
       ) do
    blocks =
      case blocks do
        [{_meta, _fun, _opts, {:__block__, _meta_block, blocks}}] -> blocks
        [{_meta, _fun, _opts, blocks}] -> [blocks]
        _else -> []
      end

    Enum.find_value(blocks, fn
      {_fun, meta, _args} = block ->
        with true <- meta[:line] == meta_node[:line] do
          {:ok, [block]}
        end

      _else ->
        false
    end)
  end

  defp do_find_block(_definition, _context) do
    false
  end

  defp do_expand_mfa(
         {{{:., _meta1, [module, fun]}, _meta2, args}, _zipper_meta} = zipper,
         mfa
       ) do
    case expand?({module, fun, length(args)}, mfa) do
      true -> {:halt, zipper, module}
      false -> {:cont, zipper, nil}
    end
  end

  defp do_expand_mfa(
         {{:&, _meta1, [{:/, _meta2, [{{:., _meta3, [module, fun]}, _meta4, _args}, arity]}]},
          _zipper_meta} = zipper,
         mfa
       ) do
    case expand?({module, fun, arity}, mfa) do
      true -> {:halt, zipper, module}
      false -> {:cont, zipper, nil}
    end
  end

  defp do_expand_mfa(zipper, _mfa) do
    {:cont, zipper, nil}
  end

  defp expand?({_module, fun, arity}, {nil, fun, arity}) do
    true
  end

  defp expand?({module1, fun, arity}, {module2, fun, arity}) do
    ends_with?(module1, module2)
  end

  defp expand?(_mfa1, _mfa2), do: false
end
