defmodule Recode.SourceTest do
  use ExUnit.Case

  alias Recode.Source

  doctest Recode.Source

  describe "new/1" do
    test "creates new source" do
      path = "test/fixtures/source/simple.ex"
      code = File.read!(path)

      source = Source.new!(path)

      assert_source(source, %{
        path: path,
        code: code,
        modules: [MyApp.Simple]
      })
    end
  end

  describe "from_string/2" do
    test "creates a source from code" do
      code = "def foo, do: :foo"
      source = Source.from_string(code)
      assert source.code == code
      assert source.path == nil
      assert source.modules == []
    end
  end

  describe "update/1" do
    test "updates the code" do
      path = "test/fixtures/source/simple.ex"
      code = File.read!(path)
      changes = String.replace(code, "MyApp", "TheApp")

      source =
        path
        |> Source.new!()
        |> Source.update(:test, code: changes)

      assert_source(source, %{
        path: path,
        code: changes,
        modules: [TheApp.Simple],
        versions: [{:code, :test, code}]
      })
    end

    test "updates the code twice" do
      path = "test/fixtures/source/simple.ex"
      code = File.read!(path)
      changes1 = String.replace(code, "MyApp", "TheApp")
      changes2 = String.replace(changes1, "TheApp", "Application")

      orig = Source.new!(path)

      source =
        orig
        |> Source.update(:foo, code: changes1)
        |> Source.update(:bar, code: changes2)

      assert orig.id == source.id

      assert_source(source, %{
        path: path,
        code: changes2,
        modules: [Application.Simple],
        versions: [
          {:code, :bar, changes1},
          {:code, :foo, code}
        ]
      })
    end

    test "updates the code and path" do
      path = "test/fixtures/source/simple.ex"
      code = File.read!(path)
      changes1 = String.replace(code, "MyApp", "TheApp")
      changes2 = "test/fixtures/source/the_app.ex"

      source =
        path
        |> Source.new!()
        |> Source.update(:foo, code: changes1)
        |> Source.update(:bar, path: changes2)

      assert_source(source, %{
        path: changes2,
        code: changes1,
        modules: [TheApp.Simple],
        versions: [
          {:path, :bar, path},
          {:code, :foo, code}
        ]
      })
    end
  end

  describe "updates/1" do
    test "returns the updates count for an unchanged source" do
      source = Source.new!("test/fixtures/source/simple.ex")

      assert Source.updates(source) == 0
    end

    test "returns the updates count for a changed source" do
      source =
        "test/fixtures/source/simple.ex"
        |> Source.new!()
        |> Source.update(:test, code: "adsf")

      assert Source.updates(source) == 1
    end
  end

  describe "path/1" do
    test "returns path" do
      path = "test/fixtures/source/simple.ex"
      source = Source.new!(path)

      assert Source.path(source) == path
    end

    test "returns current path" do
      source = Source.new!("test/fixtures/source/simple.ex")
      path = "test/fixtures/source/new.ex"

      source = Source.update(source, :test, path: path)

      assert Source.path(source) == path
    end
  end

  describe "path/2" do
    test "returns the path for the given version" do
      path = "test/fixtures/source/simple.ex"

      source =
        path
        |> Source.new!()
        |> Source.update(:test, path: "a.ex")
        |> Source.update(:test, path: "b.ex")
        |> Source.update(:test, path: "c.ex")

      assert Source.path(source, 0) == path
      assert Source.path(source, 1) == "a.ex"
      assert Source.path(source, 2) == "b.ex"
      assert Source.path(source, 3) == "c.ex"
    end

    test "returns the path for given version without path changes" do
      path = "test/fixtures/source/simple.ex"

      source =
        path
        |> Source.new!()
        |> Source.update(:test, code: "a.ex")
        |> Source.update(:test, code: "b.ex")

      assert Source.path(source, 0) == path
      assert Source.path(source, 1) == path
      assert Source.path(source, 2) == path
    end
  end

  describe "code/2" do
    test "returns the code for the given version without code changes" do
      path = "test/fixtures/source/simple.ex"
      code = File.read!(path)

      source =
        path
        |> Source.new!()
        |> Source.update(:test, path: "a.ex")
        |> Source.update(:test, path: "b.ex")

      assert Source.code(source, 0) == code
      assert Source.code(source, 1) == code
      assert Source.code(source, 2) == code
    end

    test "returns the code for given version" do
      code = "a + b"

      source =
        code
        |> Source.from_string()
        |> Source.update(:test, code: "a + c")
        |> Source.update(:test, code: "a + d")

      assert Source.code(source, 0) == code
      assert Source.code(source, 1) == "a + c\n"
      assert Source.code(source, 2) == "a + d\n"
    end
  end

  describe "modules/2" do
    test "returns the modules for the given version" do
      path = "test/fixtures/source/simple.ex"
      code = File.read!(path)
      changes1 = String.replace(code, "MyApp", "TheApp")
      changes2 = String.replace(code, "MyApp", "AnApp")

      source =
        path
        |> Source.new!()
        |> Source.update(:test, code: changes1)
        |> Source.update(:test, code: changes2)

      assert Source.modules(source, 0) == [MyApp.Simple]
      assert Source.modules(source, 1) == [TheApp.Simple]
      assert Source.modules(source, 2) == [AnApp.Simple]
    end
  end

  describe "debug_info/2" do
    test "returns debug info" do
      source = Source.new!("lib/recode/source.ex")
      dbgi = Source.debug_info(source, Recode.Source)

      check =
        case dbgi do
          {:ok, _dbgi} -> true
          {:error, :cover_compiled} -> true
        end

      assert check
    end

    test "returns an error tuple for an unknown module" do
      assert "a + b" |> Source.from_string() |> Source.debug_info(Unknown) ==
               {:error, :non_existing}
    end
  end

  defp hash(path, code), do: :crypto.hash(:md5, path <> code)

  defp assert_source(%Source{} = source, expected) do
    assert is_reference(source.id)
    assert source.hash == hash(expected.path, expected.code)
    assert source.path == expected.path
    assert source.code == expected.code
    assert source.modules == expected.modules
    assert source.versions == Map.get(expected, :versions, [])
    assert source.issues == Map.get(expected, :issues, [])
  end
end
