defmodule Recode.CodeMod.ReferencesTest do
  alias Recode.CodeMod.DebugInfo
  alias Recode.CodeMod.References
  alias Rewrite.Source

  use ExUnit.Case, async: true

  test "it should return the references when alias as anonymous function" do
    path = "test/fixtures/rename/lib/anonymous_function.ex"
    source = Source.read!(path)
    calls = DebugInfo.calls(source)

    result = References.search_references(source, calls)

    assert result == [
             %Recode.CodeMod.References{
               mfa: {Rename.Bar, :baz, 1},
               range: %{end: %{column: 55, line: 15}, start: %{column: 52, line: 15}},
               debug_line: 15
             },
             %Recode.CodeMod.References{
               mfa: {Rename.Bar, :baz, 1},
               range: %{end: %{column: 41, line: 11}, start: %{column: 38, line: 11}},
               debug_line: 11
             }
           ]
  end

  test "it should return the references when module name changed by alias_as" do
    path = "test/fixtures/rename/lib/as.ex"
    source = Source.read!(path)
    calls = DebugInfo.calls(source)

    result = References.search_references(source, calls)

    assert result == [
             %Recode.CodeMod.References{
               mfa: {Rename.Baz, :baz, 1},
               range: %{end: %{column: 13, line: 29}, start: %{column: 10, line: 29}},
               debug_line: 29
             },
             %Recode.CodeMod.References{
               mfa: {Rename.BarBaz, :baz, 3},
               range: %{end: %{column: 46, line: 25}, start: %{column: 43, line: 25}},
               debug_line: 25
             },
             %Recode.CodeMod.References{
               mfa: {Rename.Baz, :baz, 0},
               range: %{end: %{column: 25, line: 25}, start: %{column: 22, line: 25}},
               debug_line: 25
             },
             %Recode.CodeMod.References{
               mfa: {Rename.Bar, :baz, 0},
               range: %{end: %{column: 13, line: 25}, start: %{column: 10, line: 25}},
               debug_line: 25
             },
             %Recode.CodeMod.References{
               mfa: {Rename.Bar, :baz, 0},
               range: %{end: %{column: 27, line: 22}, start: %{column: 24, line: 22}},
               debug_line: 22
             }
           ]
  end

  test "it should return the references when import" do
    path = "test/fixtures/rename/lib/import.ex"
    source = Source.read!(path)
    calls = DebugInfo.calls(source)

    result = References.search_references(source, calls)

    assert result == [
             %Recode.CodeMod.References{
               mfa: {Rename.Baz, :baz, 1},
               range: %{end: %{column: 17, line: 13}, start: %{column: 14, line: 13}},
               debug_line: 13
             },
             %Recode.CodeMod.References{
               mfa: {Rename.Baz, :baz, 0},
               range: %{end: %{column: 8, line: 13}, start: %{column: 5, line: 13}},
               debug_line: 13
             },
             %Recode.CodeMod.References{
               mfa: {Rename.Baz, :baz, 0},
               range: %{end: %{column: 23, line: 10}, start: %{column: 20, line: 10}},
               debug_line: 10
             }
           ]
  end

  test "it should return the references when definied in the same moudle" do
    # TODO: deal with the references which are defined in the same module
    path = "test/fixtures/rename/lib/definition.ex"
    source = Source.read!(path)
    calls = DebugInfo.calls(source)

    result = References.search_references(source, calls)
    assert result == []
  end

  test "it should return the references when there are other definitions" do
    path = "test/fixtures/rename/lib/other_definition.ex"
    source = Source.read!(path)
    calls = DebugInfo.calls(source)

    result = References.search_references(source, calls)

    assert result == [
             %Recode.CodeMod.References{
               mfa: {Rename.Bar, :baz, 1},
               range: %{end: %{column: 12, line: 21}, start: %{column: 9, line: 21}},
               debug_line: 21
             }
           ]
  end

  test "it should return the references when in the setup block" do
    path = "test/fixtures/rename/lib/setup_do.exs"
    source = Source.read!(path)
    calls = DebugInfo.calls(source)

    result = References.search_references(source, calls)

    assert result == [
             %Recode.CodeMod.References{
               debug_line: 33,
               mfa: {Rename.Bar, :baz, 1},
               range: %{end: %{column: 15, line: 33}, start: %{column: 12, line: 33}}
             },
             %Recode.CodeMod.References{
               mfa: {Rename.Bar, :baz, 1},
               range: %{end: %{column: 8, line: 32}, start: %{column: 5, line: 32}},
               debug_line: 32
             },
             %Recode.CodeMod.References{
               mfa: {Rename.Bar, :baz, 1},
               range: %{end: %{column: 8, line: 27}, start: %{column: 5, line: 27}},
               debug_line: 27
             },
             %Recode.CodeMod.References{
               mfa: {Rename.Bar, :baz, 1},
               range: %{end: %{column: 15, line: 17}, start: %{column: 12, line: 17}},
               debug_line: 17
             },
             %Recode.CodeMod.References{
               mfa: {Rename.Bar, :baz, 1},
               range: %{end: %{column: 8, line: 16}, start: %{column: 5, line: 16}},
               debug_line: 16
             },
             %Recode.CodeMod.References{
               mfa: {Rename.Bar, :baz, 0},
               range: %{end: %{column: 8, line: 11}, start: %{column: 5, line: 11}},
               debug_line: 11
             }
           ]
  end

  test "it should return the references when using use to import" do
    path = "test/fixtures/rename/lib/use_import.ex"
    source = Source.read!(path)
    calls = DebugInfo.calls(source)

    result = References.search_references(source, calls)

    assert result == [
             %Recode.CodeMod.References{
               debug_line: 19,
               mfa: {Rename.Bar, :baz, 0},
               range: %{end: %{column: 8, line: 19}, start: %{column: 5, line: 19}}
             },
             %Recode.CodeMod.References{
               debug_line: 16,
               mfa: {Rename.Bar, :baz, 0},
               range: %{end: %{column: 23, line: 16}, start: %{column: 20, line: 16}}
             }
           ]
  end
end
