defmodule Recode.ModuleInfoTest do
  use ExUnit.Case

  alias Recode.ModuleInfo

  describe "new/1" do
    test "creates a project map form a simple module" do
      assert ModuleInfo.from_code(File.read!("test/fixtures/traverse/simple.ex")) ==
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
  end
end
