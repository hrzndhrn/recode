defmodule Recode.CodeMod.DebugInfoTest do
  use ExUnit.Case, async: true

  alias Recode.CodeMod.DebugInfo
  alias Rewrite.Source

  defp filter_modules(calls, modules) do
    Enum.filter(calls, fn call ->
      Enum.member?(modules, call.module)
    end)
  end

  describe "basic cases of `calls/1`" do
    test "it should return the calls when use the normal way" do
      module = """
      defmodule Rename.Bar do
        def bar, do: :baz

        def bar(_a), do: :baz
      end

      defmodule Rename.Foo do
        import Rename.Bar

        def foo(), do: bar()
                      #^(10, 18)

        def foo(a), do: bar(a)
                       #^(13, 19)
      end
      """

      result = DebugInfo.calls(module)

      assert result == [
               %Recode.CodeMod.DebugInfo.Call{
                 module: Rename.Bar,
                 func: :bar,
                 line: 10,
                 arity: 0
               },
               %Recode.CodeMod.DebugInfo.Call{
                 module: Rename.Bar,
                 func: :bar,
                 line: 13,
                 arity: 1
               }
             ]
    end

    test "it should return the calls when use pipeline" do
      module = """
      defmodule Rename.Bar do
        def bar, do: :baz

        def bar(_a), do: :baz

        def bar(a, b), do: {a, b}
      end

      defmodule Rename.Foo do
        import Rename.Bar

        def foo(), do: bar()
                      #^(12, 18)

        def foo(a), do: bar() |> bar() |> bar(a)
                                         #^(15, 37)
      end
      """

      result = DebugInfo.calls(module)

      assert result == [
               %Recode.CodeMod.DebugInfo.Call{
                 module: Rename.Bar,
                 func: :bar,
                 line: 12,
                 arity: 0
               },
               %Recode.CodeMod.DebugInfo.Call{
                 module: Rename.Bar,
                 func: :bar,
                 line: 15,
                 arity: 0
               },
               %Recode.CodeMod.DebugInfo.Call{
                 module: Rename.Bar,
                 func: :bar,
                 line: 15,
                 arity: 1
               },
               %Recode.CodeMod.DebugInfo.Call{
                 module: Rename.Bar,
                 func: :bar,
                 line: 15,
                 arity: 2
               }
             ]
    end

    test "it should return correct calls when there are multiple calls in one line" do
      module = """
      defmodule Rename.Bar do
        def bar, do: :bar
      end

      defmodule Rename.Baz do
        def baz, do: :baz

        def baz(1), do: :baz_1
      end

      defmodule Rename.BarBaz do
        def baz(1, 2, 3), do: :bar_baz
      end

      defmodule Rename.Foo do
        alias Rename.Bar, as: BarAlias
        alias Rename.Baz, as: BazAlias

        def foo(atom)

        def foo(:a), do: BarAlias.bar()

        def foo(:b) do
          {BarAlias.bar(), BazAlias.baz(), Rename.BarBaz.baz(1, 2, 3)}
        end
      end
      """

      result = DebugInfo.calls(module)

      assert result == [
               %Recode.CodeMod.DebugInfo.Call{module: Rename.Bar, func: :bar, line: 21, arity: 0},
               %Recode.CodeMod.DebugInfo.Call{module: nil, func: :{}, line: 24, arity: 3},
               %Recode.CodeMod.DebugInfo.Call{module: Rename.Bar, func: :bar, line: 24, arity: 0},
               %Recode.CodeMod.DebugInfo.Call{module: Rename.Baz, func: :baz, line: 24, arity: 0},
               %Recode.CodeMod.DebugInfo.Call{
                 module: Rename.BarBaz,
                 func: :baz,
                 line: 24,
                 arity: 3
               }
             ]
    end
  end

  test "it should return the calls when using the anonyous" do
    path = "test/fixtures/rename/lib/anonymous_function.ex"
    source = Source.read!(path)

    result = source |> DebugInfo.calls() |> filter_modules([Rename.Bar])

    assert result == [
             %Recode.CodeMod.DebugInfo.Call{module: Rename.Bar, func: :baz, line: 11, arity: 1},
             %Recode.CodeMod.DebugInfo.Call{module: Rename.Bar, func: :baz, line: 15, arity: 1}
           ]
  end

  test "it should return the calls when module name changed by alias_as" do
    path = "test/fixtures/rename/lib/as.ex"
    source = Source.read!(path)

    result =
      source |> DebugInfo.calls() |> filter_modules([Rename.BarBaz, Rename.Baz, Rename.Bar])

    assert result == [
             %Recode.CodeMod.DebugInfo.Call{
               module: Rename.Bar,
               arity: 0,
               func: :baz,
               line: 22
             },
             %Recode.CodeMod.DebugInfo.Call{module: Rename.Bar, func: :baz, line: 25, arity: 0},
             %Recode.CodeMod.DebugInfo.Call{module: Rename.Baz, func: :baz, line: 25, arity: 0},
             %Recode.CodeMod.DebugInfo.Call{
               arity: 3,
               func: :baz,
               line: 25,
               module: Rename.BarBaz
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 1,
               func: :baz,
               line: 29,
               module: Rename.Baz
             }
           ]
  end

  test "it should return the calls which some of its own defined functions" do
    path = "test/fixtures/rename/lib/definition.ex"
    source = Source.read!(path)

    result = DebugInfo.calls(source) |> filter_modules([Rename.Baz, nil])

    assert result == [
             %Recode.CodeMod.DebugInfo.Call{
               arity: 1,
               func: :baz,
               line: 8,
               module: nil
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 3,
               func: :baz,
               line: 13,
               module: nil
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 3,
               func: :baz,
               line: 17,
               module: nil
             }
           ]
  end

  test "it should return the calls when import" do
    path = "test/fixtures/rename/lib/import.ex"
    source = Source.read!(path)

    result = DebugInfo.calls(source) |> filter_modules([Rename.Baz])

    assert result == [
             %Recode.CodeMod.DebugInfo.Call{
               arity: 0,
               func: :baz,
               line: 10,
               module: Rename.Baz
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 0,
               func: :baz,
               line: 13,
               module: Rename.Baz
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 1,
               func: :baz,
               line: 13,
               module: Rename.Baz
             }
           ]
  end

  test "it should return the calls when import with only" do
    path = "test/fixtures/rename/lib/import_with_only.ex"
    source = Source.read!(path)

    result = DebugInfo.calls(source) |> filter_modules([Rename.Bar])

    assert result == [
             %Recode.CodeMod.DebugInfo.Call{
               arity: 0,
               func: :baz,
               line: 10,
               module: Rename.Bar
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 0,
               func: :baz,
               line: 13,
               module: Rename.Bar
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 1,
               func: :baz,
               line: 13,
               module: Rename.Bar
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 0,
               func: :baz,
               line: 25,
               module: Rename.Bar
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 1,
               func: :baz,
               line: 25,
               module: Rename.Bar
             }
           ]
  end

  test "it should return the calls when there are other definitions" do
    path = "test/fixtures/rename/lib/other_definition.ex"
    source = Source.read!(path)

    result = DebugInfo.calls(source) |> filter_modules([Rename.Bar, nil])

    assert result == [
             %Recode.CodeMod.DebugInfo.Call{
               arity: 1,
               func: :baz,
               line: 17,
               module: nil
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 1,
               func: :baz,
               line: 21,
               module: Rename.Bar
             },
             %Recode.CodeMod.DebugInfo.Call{arity: 3, module: nil, func: :baz, line: 25},
             %Recode.CodeMod.DebugInfo.Call{arity: 3, module: nil, func: :baz, line: 29}
           ]
  end

  test "it should return the calls when the calls in the setup block" do
    path = "test/fixtures/rename/lib/setup_do.exs"
    source = Source.read!(path)

    result = DebugInfo.calls(source) |> filter_modules([Rename.Bar])

    # TODO: it is hard to distinguish the calls in the setup block
    assert result == [
             %Recode.CodeMod.DebugInfo.Call{
               arity: 0,
               func: :baz,
               line: 11,
               module: Rename.Bar
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 1,
               func: :baz,
               line: 16,
               module: Rename.Bar
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 1,
               func: :baz,
               line: 17,
               module: Rename.Bar
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 1,
               func: :baz,
               line: 27,
               module: Rename.Bar
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 1,
               func: :baz,
               line: 32,
               module: Rename.Bar
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 1,
               func: :baz,
               line: 33,
               module: Rename.Bar
             }
           ]
  end

  test "it should return the calls when using use to import" do
    path = "test/fixtures/rename/lib/use_import.ex"
    source = Source.read!(path)

    result = DebugInfo.calls(source)

    assert result == [
             %Recode.CodeMod.DebugInfo.Call{
               arity: 0,
               func: :baz,
               line: 16,
               module: Rename.Bar
             },
             %Recode.CodeMod.DebugInfo.Call{
               arity: 0,
               func: :baz,
               line: 19,
               module: Rename.Bar
             }
           ]
  end
end
