defmodule Recode.ProjectTest do
  use RecodeCase

  alias Recode.Project
  alias Recode.ProjectError
  alias Recode.Source

  doctest Recode.Project

  describe "new/1" do
    test "creates a project from one file" do
      inputs = ["test/fixtures/source/simple.ex"]
      assert project = Project.new(inputs)
      assert project.inputs == inputs
      assert Map.keys(project.paths) == inputs
      assert Enum.count(project.sources) == 1
    end
  end

  describe "source/2" do
    test "returns the source struct for a path" do
      path = "test/fixtures/source/simple.ex"
      project = Project.new([path])
      assert {:ok, %Source{}} = Project.source(project, path)
    end
  end

  describe "source!/2" do
    test "returns the source struct for a path" do
      path = "test/fixtures/source/simple.ex"
      project = Project.new([path])
      assert %Source{} = Project.source!(project, path)
    end

    test "raises an error for an invalid path" do
      project = Project.new(["test/fixtures/source/simple.ex"])

      assert_raise ProjectError, ~s|No source for "foo/bar.ex" found.|, fn ->
        Project.source!(project, "foo/bar.ex")
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

  describe "counts/2" do
    test "counts by the given type" do
      project =
        Project.from_sources([
          Source.from_string(":a", "a.ex"),
          Source.from_string(":b", "b.exs")
        ])

      assert Project.count(project, :sources) == 2
      assert Project.count(project, :scripts) == 1
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

  describe "save/2" do
    @describetag :tmp_dir

    test "writes sources to disk", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "test.ex")

      project =
        Project.from_sources([
          ":foo" |> Source.from_string(path) |> Source.update(Test, code: ":test")
        ])

      assert Project.save(project) == :ok
      assert File.read(path) == {:ok, ":test\n"}
    end

    test "creates dir", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "new_dir/test.ex")

      project =
        Project.from_sources([
          ":foo\n" |> Source.from_string() |> Source.update(Test, path: path)
        ])

      assert Project.save(project) == :ok
      assert File.read(path) == {:ok, ":foo\n"}
    end

    test "removes old file", %{tmp_dir: tmp_dir} do
      foo = Path.join(tmp_dir, "foo.ex")
      bar = Path.join(tmp_dir, "bar.ex")
      File.write!(foo, ":bar")

      project =
        Project.from_sources([
          foo |> Source.new!() |> Source.update(:test, path: bar)
        ])

      assert Project.save(project) == :ok
      refute File.exists?(foo)
      assert File.read(bar) == {:ok, ":bar"}
    end

    test "excludes files", %{tmp_dir: tmp_dir} do
      foo = Path.join(tmp_dir, "foo.ex")
      bar = Path.join(tmp_dir, "bar.ex")
      File.write!(foo, ":foo")

      project =
        Project.from_sources([
          foo |> Source.new!() |> Source.update(:test, path: bar)
        ])

      assert Project.save(project, [bar]) == :ok
      assert File.exists?(foo)
    end

    test "deletes files", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "foo.ex")
      File.write!(path, ":bar")

      project =
        Project.from_sources([
          path |> Source.new!() |> Source.del()
        ])

      assert Project.save(project, ["bar.ex"]) == :ok
      refute File.exists?("foo.ex")
    end

    test "returns {:error, :conflicts}", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "foo.ex")
      File.write!(path, ":bar")

      project =
        Project.from_sources([
          path |> Source.new!() |> Source.update(:test, code: ":new"),
          path |> Source.new!() |> Source.update(:test, code: ":new")
        ])

      assert Project.save(project) == {:error, :conflicts}
      assert Project.save(project, [path]) == :ok
    end

    test "returns {:error, errors}", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "foo.ex")
      File.write!(path, ":bar")
      System.cmd("chmod", ["-w", path])

      project =
        Project.from_sources([
          path |> Source.new!() |> Source.update(:test, code: ":new")
        ])

      assert Project.save(project) == {:error, [{path, :eacces}]}
    end

    test "ignores sources without path" do
      project = Project.from_sources([Source.from_string(":a")])

      assert Project.save(project) == :ok
    end

    test "does nothing without updates", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "foo.ex")
      File.write!(path, ":bar")

      project = Project.from_sources([Source.new!(path)])

      assert Project.save(project) == :ok
    end
  end
end
