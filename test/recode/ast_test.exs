defmodule Recode.ASTTest do
  use ExUnit.Case

  alias Recode.AST

  doctest Recode.AST, import: true

  describe "reduce/3" do
    test "reduces the AST" do
      ast =
        Code.string_to_quoted!("""
        defmodule Foo do
          def x, do: :y
        end
        """)

      fun = fn
        {form, _meta, _args}, acc when is_atom(form) -> [form | acc]
        _ast, acc -> acc
      end

      assert AST.reduce(ast, [], fun) == [:x, :def, :__aliases__, :defmodule]
    end

    test "compares to Macro.prewalk/3" do
      # Macro.prewalk/3 uses Macro.travers/4
      ast =
        Code.string_to_quoted!(~s'''
        defmodule Foo do
          @moduledoc """
          The Foo
          """
          @data :y

          def x, do: @data

          def rev(list), do: Enum.reverse(list)
        end
        ''')

      collect = fn ast, acc -> {ast, [ast | acc]} end
      {_ast, prewalk} = Macro.prewalk(ast, [], collect)

      collect = fn ast, acc -> [ast | acc] end
      assert AST.reduce(ast, [], collect) == prewalk
    end
  end

  describe "reduce_while/3" do
    test "reduces the AST" do
      ast =
        Code.string_to_quoted!("""
        defmodule Foo do
          def x, do: :y
        end
        """)

      fun = fn
        {form, _meta, _args}, acc when is_atom(form) -> {:cont, [form | acc]}
        _ast, acc -> {:cont, acc}
      end

      assert AST.reduce_while(ast, [], fun) == [:x, :def, :__aliases__, :defmodule]
    end

    test "skips parts of the AST" do
      ast =
        Code.string_to_quoted!("""
        defmodule Foo do
          def x, do: :y
        end
        """)

      fun = fn
        {:def, _meta, _args}, acc -> {:skip, acc}
        {form, _meta, _args}, acc when is_atom(form) -> {:cont, [form | acc]}
        _ast, acc -> {:cont, acc}
      end

      assert AST.reduce_while(ast, [], fun) == [:__aliases__, :defmodule]
    end

    test "compares to Macro.prewalk/3" do
      # Macro.prewalk/3 uses Macro.travers/4
      ast =
        Code.string_to_quoted!(~s'''
        defmodule Foo do
          @moduledoc """
          The Foo
          """
          @data :y

          def x, do: @data

          def rev(list), do: Enum.reverse(list)
        end
        ''')

      collect = fn ast, acc -> {ast, [ast | acc]} end
      {_ast, prewalk} = Macro.prewalk(ast, [], collect)

      collect = fn ast, acc -> {:cont, [ast | acc]} end
      assert AST.reduce_while(ast, [], collect) == prewalk
    end
  end

  describe "multiline?/1" do
    test "with operator" do
      assert "x && y" |> Sourceror.parse_string!() |> AST.multiline?() == false
      assert "x &&\ny" |> Sourceror.parse_string!() |> AST.multiline?() == true
    end

    test "with empty list" do
      assert AST.multiline?([]) == false
    end
  end
end
