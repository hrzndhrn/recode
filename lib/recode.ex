defmodule Recode do
  # alias Recode.Context
  # alias Sourceror.Zipper

  @type aliases :: [atom()]
  @type mod :: module() | aliases()
  @type mod_fun_arity :: {mod() | nil, fun() | nil, arity() | nil}

  # @deprecated "use Recode.Context.traverse/2"
  # def traverse(zipper, fun) when is_function(fun, 2) do
  #   zipper
  #   |> run_traverse(%Context{}, fun)
  #   |> elem(0)
  # end

  # @deprecated "use Recode.Context.traverse/3"
  # def traverse(zipper, acc, fun) when is_function(fun, 3) do
  #   {zipper, {_context, acc}} = run_traverse(zipper, %Context{}, acc, fun)
  #   {zipper, acc}
  # end

  # defp run_traverse(zipper, context, fun) do
  #   Zipper.traverse_while(zipper, context, fn zipper, context ->
  #     do_traverse(zipper, context, fun)
  #   end)
  # end

  # defp run_traverse(zipper, context, acc, fun) do
  #   Zipper.traverse_while(zipper, {context, acc}, fn zipper, {context, acc} ->
  #     do_traverse(zipper, context, acc, fun)
  #   end)
  # end

  # # do_traverse/3

  # defp do_traverse({{:defmodule, _, [{:__aliases__, _, name} | _]}, _} = zipper, context, fun) do
  #   case ends_with?(context.module, name) do
  #     true ->
  #       cont(zipper, context, fun)

  #     false ->
  #       {{ast, _}, %Context{assigns: assigns}} =
  #         run_traverse(sub_zipper(zipper), Context.nested_module(context, name), fun)

  #       {:skip, Zipper.replace(zipper, ast), Context.assigns(context, assigns)}
  #   end
  # end

  # defp do_traverse({{:alias, _meta, args}, _zipper_meta} = zipper, context, fun)
  #      when not is_nil(args) do
  #   cont(zipper, Context.add_aliases(context, aliases(args)), fun)
  # end

  # defp do_traverse({{:import, _, [arg, opts]}, _} = zipper, context, fun) do
  #   cont(zipper, Context.add_import(context, get_alias(arg), eval(opts)), fun)
  # end

  # defp do_traverse({{:import, _, [arg]}, _} = zipper, context, fun) do
  #   cont(zipper, Context.add_import(context, get_alias(arg)), fun)
  # end

  # defp do_traverse({{:use, _, [arg, opts]}, _} = zipper, context, fun) do
  #   cont(zipper, Context.add_use(context, get_alias(arg), eval(opts)), fun)
  # end

  # defp do_traverse({{:use, _, [arg]}, _} = zipper, context, fun) do
  #   cont(zipper, Context.add_use(context, get_alias(arg)), fun)
  # end

  # defp do_traverse({{definition, _, args}, _} = zipper, context, fun)
  #      when definition in [:def, :defp, :defmacro, :defmacrop] do
  #   definition = definition(definition, args)

  #   case context.definition == definition do
  #     true ->
  #       cont(zipper, context, fun)

  #     false ->
  #       {{ast, _}, context} =
  #         run_traverse(sub_zipper(zipper), Context.definition(context, definition), fun)

  #       {:skip, Zipper.replace(zipper, ast), Context.definition(context, nil)}
  #   end
  # end

  # defp do_traverse(zipper, context, fun) do
  #   cont(zipper, context, fun)
  # end

  # # do_traverse/4

  # defp do_traverse(
  #        {{:defmodule, _, [{:__aliases__, _, name} | _]}, _} = zipper,
  #        context,
  #        acc,
  #        fun
  #      ) do
  #   case ends_with?(context.module, name) do
  #     true ->
  #       cont(zipper, context, acc, fun)

  #     false ->
  #       {{ast, _}, {%Context{assigns: assigns}, acc}} =
  #         run_traverse(sub_zipper(zipper), Context.nested_module(context, name), acc, fun)

  #       {:skip, Zipper.replace(zipper, ast), {Context.assigns(context, assigns), acc}}
  #   end
  # end

  # defp do_traverse({{:alias, _, args}, _} = zipper, context, acc, fun) when not is_nil(args) do
  #   cont(zipper, Context.add_aliases(context, aliases(args)), acc, fun)
  # end

  # defp do_traverse({{:import, _, [arg, opts]}, _} = zipper, context, acc, fun) do
  #   cont(zipper, Context.add_import(context, get_alias(arg), eval(opts)), acc, fun)
  # end

  # defp do_traverse({{:import, _, [arg]}, _} = zipper, context, acc, fun) do
  #   cont(zipper, Context.add_import(context, get_alias(arg)), acc, fun)
  # end

  # defp do_traverse({{:use, _, [arg, opts]}, _} = zipper, context, acc, fun) do
  #   cont(zipper, Context.add_use(context, get_alias(arg), eval(opts)), acc, fun)
  # end

  # defp do_traverse({{:use, _, [arg]}, _} = zipper, context, acc, fun) do
  #   cont(zipper, Context.add_use(context, get_alias(arg)), acc, fun)
  # end

  # defp do_traverse({{:require, _, [arg, opts]}, _} = zipper, context, acc, fun) do
  #   cont(zipper, Context.add_require(context, get_alias(arg), eval(opts)), acc, fun)
  # end

  # defp do_traverse({{:require, _, [arg]}, _} = zipper, context, acc, fun) do
  #   cont(zipper, Context.add_require(context, get_alias(arg)), acc, fun)
  # end

  # defp do_traverse({{definition, _meta, args}, _zipper_meta} = zipper, context, acc, fun)
  #      when definition in [:def, :defp, :defmacro, :defmacrop] and length(args) == 2 do
  #   definition = definition(definition, args)

  #   case context.definition == definition do
  #     true ->
  #       cont(zipper, context, acc, fun)

  #     false ->
  #       {{ast, _}, {context, acc}} =
  #         run_traverse(sub_zipper(zipper), Context.definition(context, definition), acc, fun)

  #       {:skip, Zipper.replace(zipper, ast), {Context.definition(context, nil), acc}}
  #   end
  # end

  # defp do_traverse(zipper, context, acc, fun) do
  #   cont(zipper, context, acc, fun)
  # end

  # # other helpers

  # defp eval(ast) do
  #   ast |> Code.eval_quoted() |> elem(0)
  # end

  # defp definition(kind, [{name, _, args}]), do: {kind, name, length(args)}

  # defp definition(kind, [{name, _, nil}, _]), do: {kind, name, 0}

  # defp definition(kind, [{name, _, args}, _]), do: {kind, name, length(args)}

  # defp get_alias({:__aliases__, _, name}), do: name

  # defp aliases([{{:., _, [alias, :{}]}, _, aliases}]) do
  #   base = get_alias(alias)

  #   Enum.map(aliases, fn alias ->
  #     {base ++ get_alias(alias), nil}
  #   end)
  # end

  # defp aliases([arg]), do: [{get_alias(arg), nil}]

  # defp aliases([arg, opts]), do: [{get_alias(arg), eval(opts)}]

  # defp cont(zipper, context, fun) do
  #   {zipper, context} = fun.(zipper, context)
  #   {:cont, zipper, context}
  # end

  # defp cont(zipper, context, acc, fun) do
  #   {zipper, context, acc} = fun.(zipper, context, acc)
  #   {:cont, zipper, {context, acc}}
  # end

  # defp sub_zipper({ast, _meta}), do: {ast, nil}

  # defp ends_with?(list, postfix) do
  #   case length(list) - length(postfix) do
  #     diff when diff < 0 -> false
  #     diff -> Enum.drop(list, diff) == postfix
  #   end
  # end

  # def newline(string), do: String.trim_leading(string) <> "\n"

  # def aliases, do: []
end
