defmodule Recode.ProjectTest do
  use ExUnit.Case

  alias Recode.Project
  alias Recode.ProjectError
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
  end

  describe "source/2" do
    test "returns the source struct for a module" do
      project = Project.new(["test/fixtures/source/simple.ex"])
      assert {:ok, %Source{}} = Project.source(project, MyApp.Simple)
    end
  end

  describe "source!/2" do
    test "returns the source struct for a module" do
      project = Project.new(["test/fixtures/source/simple.ex"])
      assert %Source{} = Project.source!(project, MyApp.Simple)
    end

    test "raises an error for an invalid module" do
      project = Project.new(["test/fixtures/source/simple.ex"])

      assert_raise ProjectError, "No source for Invalid.Module found.", fn ->
        Project.source!(project, Invalid.Module)
      end
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

      assert project.inputs == mapped.inputs
      assert project.modules == mapped.modules
      assert project != mapped
    end

    test "ignores errors (for now)" do
      inputs = ["test/fixtures/source/simple.ex"]

      project = Project.new(inputs)

      mapped =
        Project.map(project, fn _source ->
          :error
        end)

      assert project == mapped
    end
  end

  describe "map/3" do
    test "maps a project without any changes" do
      inputs = ["test/fixtures/source/simple.ex"]

      project = Project.new(inputs)

      mapped =
        Project.map(project, :opts, fn source, opts ->
          assert opts == :opts
          {:ok, source}
        end)

      assert project == mapped
    end
  end

  describe "update/2" do
    test "adds a source to the project" do
      project = Project.from_sources([])
      source = Source.from_string("a + b")

      project = Project.update(project, source)

      assert Map.values(project.sources) == [source]
    end
  end
end
