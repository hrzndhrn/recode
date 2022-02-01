defmodule Recode.ProjectTest do
  use ExUnit.Case

  alias Recode.ModuleInfo
  alias Recode.Project

  describe "new/1" do
    test "creates a project map form a simple module" do
      assert Project.new(["test/fixtures/traverse/simple.ex"]) ==
               %{
                 [:Traverse, :Simple] => %ModuleInfo{
                   aliases: [],
                   file: "test/fixtures/traverse/simple.ex",
                   imports: [],
                   definitions: [{:def, :foo, 1}],
                   module: Traverse.Simple,
                   requirements: [],
                   usages: []
                 }
               }
    end

    test "creates a project map from rename/lib/definition.ex" do
      assert Project.new(["test/fixtures/rename/lib/definition.ex"]) ==
               %{
                 [:Rename, :Bar] => %ModuleInfo{
                   aliases: [],
                   file: "test/fixtures/rename/lib/definition.ex",
                   imports: [],
                   definitions: [
                     {:def, :baz, 0},
                     {:def, :baz, 1},
                     {:def, :when, 2},
                     {:def, :baz, 2},
                     {:defp, :baz, 3}
                   ],
                   module: Rename.Bar,
                   requirements: [],
                   usages: []
                 }
               }
    end

    test "creates a project map from rename/lib/import.ex" do
      assert Project.new(["test/fixtures/rename/lib/import.ex"]) ==
               %{
                 [:Rename, :Bar] => %ModuleInfo{
                   aliases: [],
                   file: "test/fixtures/rename/lib/import.ex",
                   imports: [],
                   definitions: [{:def, :baz, 0}],
                   module: Rename.Bar,
                   requirements: [],
                   usages: []
                 },
                 [:Rename, :Foo] => %ModuleInfo{
                   aliases: [],
                   file: "test/fixtures/rename/lib/import.ex",
                   imports: [{[:Rename, :Bar], nil}],
                   definitions: [{:def, :foo, 1}],
                   module: Rename.Foo,
                   requirements: [],
                   usages: []
                 }
               }
    end
  end
end
