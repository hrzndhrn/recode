defmodule Recode.CodeMod.DebugInfoTest do
  use ExUnit.Case, async: true

  alias Recode.CodeMod.DebugInfo
  alias Rewrite.Source

  test "it should return the calls which some of its own defined functions" do
    # "../../fixtures/rename/lib/definition.ex"
    path = "test/fixtures/rename/lib/definition.ex"
    source = Source.read!(path)

    result = DebugInfo.calls(source)

    assert result == [
             %Recode.CodeMod.DebugInfo.Call{module: nil, func: :baz, line: 8},
             %Recode.CodeMod.DebugInfo.Call{module: nil, func: :baz, line: 13},
             %Recode.CodeMod.DebugInfo.Call{module: nil, func: :baz, line: 17},
             %Recode.CodeMod.DebugInfo.Call{module: :erlang, func: :==, line: 21},
             %Recode.CodeMod.DebugInfo.Call{module: :erlang, func: :+, line: 21}
           ]
  end

  test "it should return the calls when using the anonyous" do
    path = "test/fixtures/rename/lib/anonymous_function.ex"
    source = Source.read!(path)

    result = DebugInfo.calls(source)

    # TODO: there are some duplicated
    assert result == [
             %Recode.CodeMod.DebugInfo.Call{module: Enum, func: :map, line: 15},
             %Recode.CodeMod.DebugInfo.Call{module: Rename.Bar, func: :baz, line: 15},
             %Recode.CodeMod.DebugInfo.Call{module: Enum, func: :map, line: 11},
             %Recode.CodeMod.DebugInfo.Call{module: Rename.Bar, func: :baz, line: 11}
           ]
  end

  test "it should return the calls when using use to import" do
    path = "test/fixtures/rename/lib/use_import.ex"
    source = Source.read!(path)

    result = DebugInfo.calls(source)

    assert result == [
             %Recode.CodeMod.DebugInfo.Call{module: Rename.Bar, func: :baz, line: 16},
             %Recode.CodeMod.DebugInfo.Call{module: Rename.Bar, func: :baz, line: 19}
           ]
  end

  test "it should return the calls when the calls in the setup block" do
    path = "test/fixtures/rename/lib/setup_do.exs"
    source = Source.read!(path)

    result = DebugInfo.calls(source)

    # TODO: there are some verbose call 
    assert result == [
             %Recode.CodeMod.DebugInfo.Call{func: :%, line: 21, module: nil},
             %Recode.CodeMod.DebugInfo.Call{func: :%{}, line: 21, module: nil},
             %Recode.CodeMod.DebugInfo.Call{func: :%{}, line: 21, module: nil},
             %Recode.CodeMod.DebugInfo.Call{func: :%{}, line: 21, module: nil},
             %Recode.CodeMod.DebugInfo.Call{func: :%{}, line: 21, module: nil},
             %Recode.CodeMod.DebugInfo.Call{func: :__merge__, line: 21, module: ExUnit.Callbacks},
             %Recode.CodeMod.DebugInfo.Call{func: :__ex_unit_setup_0, line: 21, module: nil},
             %Recode.CodeMod.DebugInfo.Call{func: :=, line: 26, module: nil},
             %Recode.CodeMod.DebugInfo.Call{func: :baz, line: 27, module: Rename.Bar},
             %Recode.CodeMod.DebugInfo.Call{func: :baz, line: 32, module: Rename.Bar},
             %Recode.CodeMod.DebugInfo.Call{func: :baz, line: 33, module: Rename.Bar},
             %Recode.CodeMod.DebugInfo.Call{module: :erlang, func: :orelse, line: 33},
             %Recode.CodeMod.DebugInfo.Call{module: :erlang, func: :"=:=", line: 33},
             %Recode.CodeMod.DebugInfo.Call{module: :erlang, func: :"=:=", line: 33},
             %Recode.CodeMod.DebugInfo.Call{module: :erlang, func: :error, line: 33},
             %Recode.CodeMod.DebugInfo.Call{
               module: ExUnit.AssertionError,
               func: :exception,
               line: 33
             },
             %Recode.CodeMod.DebugInfo.Call{module: Kernel, func: :inspect, line: 33},
             %Recode.CodeMod.DebugInfo.Call{func: :%, line: 6, module: nil},
             %Recode.CodeMod.DebugInfo.Call{func: :%{}, line: 6, module: nil},
             %Recode.CodeMod.DebugInfo.Call{func: :%{}, line: 6, module: nil},
             %Recode.CodeMod.DebugInfo.Call{func: :%{}, line: 6, module: nil},
             %Recode.CodeMod.DebugInfo.Call{func: :%{}, line: 6, module: nil},
             %Recode.CodeMod.DebugInfo.Call{func: :__merge__, line: 6, module: ExUnit.Callbacks},
             %Recode.CodeMod.DebugInfo.Call{func: :__ex_unit_setup_0, line: 6, module: nil},
             %Recode.CodeMod.DebugInfo.Call{func: :baz, line: 11, module: Rename.Bar},
             %Recode.CodeMod.DebugInfo.Call{func: :baz, line: 16, module: Rename.Bar},
             %Recode.CodeMod.DebugInfo.Call{func: :baz, line: 17, module: Rename.Bar},
             %Recode.CodeMod.DebugInfo.Call{module: :erlang, func: :orelse, line: 17},
             %Recode.CodeMod.DebugInfo.Call{module: :erlang, func: :"=:=", line: 17},
             %Recode.CodeMod.DebugInfo.Call{module: :erlang, func: :"=:=", line: 17},
             %Recode.CodeMod.DebugInfo.Call{module: :erlang, func: :error, line: 17},
             %Recode.CodeMod.DebugInfo.Call{
               module: ExUnit.AssertionError,
               func: :exception,
               line: 17
             },
             %Recode.CodeMod.DebugInfo.Call{module: Kernel, func: :inspect, line: 17}
           ]
  end
end
