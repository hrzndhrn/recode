defmodule InfoTest do
  use ExUnit.Case

  alias Recode.Source.Info

  describe "new/1" do
    test "creates an info struct from simple module" do
      assert Info.from_code(File.read!("test/fixtures/source/simple.ex")) ==
               [
                 %Info{
                   aliases: [],
                   definitions: [{:def, :foo, 1}],
                   imports: [],
                   module: MyApp.Simple,
                   requirements: [],
                   usages: []
                 }
               ]
    end

    test "creates two info structs" do
      assert Info.from_code(File.read!("test/fixtures/source/double.ex")) ==
               [
                 %Info{
                   aliases: [],
                   definitions: [{:def, :foo, 1}, {:defp, :bar, 1}],
                   imports: [],
                   module: Double.Bar,
                   requirements: [],
                   usages: []
                 },
                 %Info{
                   aliases: [],
                   definitions: [{:def, :foo, 1}],
                   imports: [],
                   module: Double.Foo,
                   requirements: [],
                   usages: []
                 }
               ]
    end

    test "creates two info structs from nested modules" do
      assert Info.from_code(File.read!("test/fixtures/source/nested.ex")) ==
               [
                 %Info{
                   aliases: [],
                   definitions: [{:def, :foo, 1}],
                   imports: [],
                   module: Double.Foo,
                   requirements: [],
                   usages: []
                 },
                 %Info{
                   aliases: [],
                   definitions: [{:def, :foo, 1}, {:defp, :bar, 1}],
                   imports: [],
                   module: Double.Foo.Bar,
                   requirements: [],
                   usages: []
                 }
               ]
    end
  end
end
