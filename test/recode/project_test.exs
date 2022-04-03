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

      mapped = Project.map(project, fn source -> source end)

      assert project == mapped
    end

    test "maps a project" do
      inputs = ["test/fixtures/source/simple.ex"]

      project = Project.new(inputs)

      mapped =
        Project.map(project, fn source ->
          Source.update(source, :test, path: "new/path/simple.ex")
        end)

      assert project.inputs == mapped.inputs
      assert project.modules == mapped.modules
      assert project != mapped
    end
  end

  describe "map/3" do
    test "maps a project without any changes" do
      inputs = ["test/fixtures/source/simple.ex"]

      project = Project.new(inputs)

      mapped =
        Project.map(project, :opts, fn source, opts ->
          assert opts == :opts
          source
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

  describe "unreferenced/1" do
    test "returns an emplty list" do
      project =
        Project.from_sources([
          Source.from_string(":a", "a.exs"),
          Source.from_string(":b", "b.exs"),
          Source.from_string(":c", "c.exs")
        ])

      assert Project.unreferenced(project) == []
    end

    test "returns an empty list when exchanging files" do
      project =
        Project.from_sources([
          Source.from_string(":a", "a.exs"),
          ":b" |> Source.from_string("b.exs") |> Source.update(:test, path: "c.exs"),
          ":c" |> Source.from_string("c.exs") |> Source.update(:test, path: "b.exs")
        ])

      assert Project.unreferenced(project) == []
    end

    test "returns path to unreferenced file" do
      project =
        Project.from_sources([
          Source.from_string(":a", "a.exs"),
          Source.from_string(":b", "b.exs"),
          ":c" |> Source.from_string("c.exs") |> Source.update(:test, path: "d.exs")
        ])

      assert Project.unreferenced(project) == ["c.exs"]
    end

    test "returns unreferenced paths despite overwrite" do
      project =
        Project.from_sources([
          Source.from_string(":a", "a.exs"),
          Source.from_string(":b", "b.exs"),
          ":c" |> Source.from_string("c.exs") |> Source.update(:test, path: "b.exs")
        ])

      assert Project.unreferenced(project) == ["c.exs"]
    end

    test "returns unreferenced paths despite conflict" do
      project =
        Project.from_sources([
          Source.from_string(":a", "a.exs"),
          ":b" |> Source.from_string("b.exs") |> Source.update(:test, path: "d.exs"),
          ":c" |> Source.from_string("c.exs") |> Source.update(:test, path: "d.exs")
        ])

      assert Project.unreferenced(project) == ["b.exs", "c.exs"]
    end
  end

  describe "conflicts/1" do
    test "returns an emplty map" do
      project =
        Project.from_sources([
          Source.from_string(":a", "a.exs"),
          Source.from_string(":b", "b.exs"),
          Source.from_string(":c", "c.exs")
        ])

      assert Project.conflicts(project) == %{}
    end

    test "returns an emplty map while exchanging files" do
      project =
        Project.from_sources([
          Source.from_string(":a", "a.exs"),
          ":b" |> Source.from_string("b.exs") |> Source.update(:test, path: "c.exs"),
          ":c" |> Source.from_string("c.exs") |> Source.update(:test, path: "b.exs")
        ])

      assert Project.conflicts(project) == %{}
    end

    test "returns a conflict of 2 files" do
      project =
        Project.from_sources([
          Source.from_string(":a", "a.exs"),
          ":b" |> Source.from_string("b.exs") |> Source.update(:test, path: "d.exs"),
          ":c" |> Source.from_string("c.exs") |> Source.update(:test, path: "d.exs")
        ])

      assert %{"d.exs" => sources} = Project.conflicts(project)
      assert length(sources) == 2
    end

    test "returns a conflict of 3 files" do
      project =
        Project.from_sources([
          Source.from_string(":a", "a.exs"),
          ":b" |> Source.from_string("b.exs") |> Source.update(:test, path: "d.exs"),
          ":c" |> Source.from_string("c.exs") |> Source.update(:test, path: "d.exs"),
          Source.from_string(":d", "d.exs")
        ])

      assert %{"d.exs" => sources} = Project.conflicts(project)
      assert length(sources) == 3
    end
  end

  describe "sources/1" do
    test "returns all sources" do
      project =
        Project.from_sources([
          Source.from_string(":c", "c.exs"),
          Source.from_string(":a", "a.exs"),
          Source.from_string(":b", "b.exs")
        ])

      assert project
             |> Project.sources()
             |> Enum.map(fn source -> source.path end) == ["a.exs", "b.exs", "c.exs"]
    end
  end
end
