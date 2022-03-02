defmodule Recode.ProjectTest do
  use ExUnit.Case

  alias Recode.Project
  alias Recode.Source

  describe "new/1" do
    test "creates a project from one file" do
      inputs = ["test/fixtures/source/simple.ex"]
      assert project = Project.new(inputs)
      assert project.inputs == inputs
      assert Map.keys(project.paths) == inputs
      assert Enum.count(project.sources) == 1
      assert Map.keys(project.modules) == [MyApp.Simple]
    end

    # test "creates a project" do
    #   project = Project.new(["test/fixtures/source/**/*.ex"])

    #   refute "TODO"
    # end

    # # TODO: remove this test
    # test "rename-import" do
    #   project = Project.new(["test/fixtures/rename/lib/import.ex"])
    #   Project.source(project, Rename.Bar)

    #   refute "TODO"
    # end
  end

  describe "source/2" do
    test "returns the source struct for a module" do
      project = Project.new(["test/fixtures/source/simple.ex"])
      assert {:ok, %Source{}} = Project.source(project, MyApp.Simple)
    end
  end

  describe "map/2" do
    test "maps a project without any changes" do
      inputs = ["test/fixtures/source/simple.ex"]

      project = Project.new(inputs)

      mapped =
        Project.map(project, fn source ->
          {:ok, source}
        end)

      assert project == mapped
    end

    test "maps a project" do
      inputs = ["test/fixtures/source/simple.ex"]

      project = Project.new(inputs)

      mapped =
        Project.map(project, fn source ->
          source = Source.update(source, :test, path: "new/path/simple.ex")
          {:ok, source}
        end)

      assert project == mapped
    end
  end
end
