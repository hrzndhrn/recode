defmodule Recode.Task.Rename do
  @moduledoc """
  TODO:
  - Write moduledoc
  - Add a mix task
  """

  alias Recode.AST
  alias Recode.Equal
  alias Recode.Project

  use Recode.Task

  def run(ast, opts) do
    ast
    |> Zipper.zip()
    |> Recode.traverse(fn zipper, context ->
      rename(zipper, context, opts)
    end)
    |> Zipper.root()
  end

  {
    {:., [trailing_comments: [], line: 5, column: 8],
     [
       {:__aliases__,
        [
          trailing_comments: [],
          leading_comments: [],
          last: [line: 5, column: 5],
          line: 5,
          column: 5
        ], [:Bar]},
       :baz
     ]},
    [
      trailing_comments: [],
      leading_comments: [],
      end_of_expression: [newlines: 1, line: 5, column: 15],
      closing: [line: 5, column: 14],
      line: 5,
      column: 9
    ],
    [{:x, [trailing_comments: [], leading_comments: [], line: 5, column: 13], nil}]
  }

  defp rename({{{:., _, _}, _, _} = ast, _} = zipper, context, opts) do
    case rename?(:dot, ast, context, opts) do
      false ->
        {zipper, context}

      true ->
        zipper = Zipper.replace(zipper, AST.update_mfa(ast, opts[:to]))
        {zipper, context}
    end
  end

  defp rename({{fun, _meta, _args}, _zipper_meta} = zipper, context, _opts)
       when fun in [
              :alias,
              :def,
              :defp,
              :defmacro,
              :defmacrop,
              :defdelegate,
              :defmodule,
              :__aliases__,
              :__block__
            ] do
    {zipper, context}
  end

  # TODO: merge the next two functions?
  defp rename({{fun, _meta, nil} = ast, _zipper_meta} = zipper, context, opts)
       when is_atom(fun) do
    case rename?(:function, ast, context, opts) && do_block?(zipper) do
      false ->
        {zipper, context}

      true ->
        zipper = Zipper.replace(zipper, AST.update_function(ast, opts[:to]))

        {zipper, context}
    end
  end

  defp rename({{fun, _meta, _args} = ast, _zipper_meta} = zipper, context, opts)
       when is_atom(fun) do
    case rename?(:function, ast, context, opts) do
      false ->
        {zipper, context}

      true ->
        zipper = Zipper.replace(zipper, AST.update_function(ast, opts[:to]))

        {zipper, context}
    end
  end

  defp rename(zipper, context, _) do
    {zipper, context}
  end

  defp do_block?(zipper) do
    zipper |> Zipper.next() |> Zipper.node() |> AST.do_block?()
  end

  defp rename?(:dot, ast, context, opts) do
    mfa = AST.get_mfa(ast)
    mfa = Project.mfa(opts[:project], context, mfa)
    Equal.mfa?(mfa, opts[:from])
  end

  defp rename?(:function, ast, context, opts) do
    mfa = AST.get_mfa(ast)
    mfa = Project.mfa(opts[:project], context, mfa)
    Equal.mfa?(mfa, opts[:from])
  end
end
