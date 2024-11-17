defmodule Recode.ManifestTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Recode.Manifest
  alias Rewrite.Source

  @manifest_file "recode.issues"

  setup do
    File.rm(manifest())
    :ok
  end

  describe "read/1" do
    test "returns manifest" do
      File.write!(manifest(), """
      config_file
      file1
      file2
      """)

      assert {timestamp, config_file, files} = Manifest.read(manifest: true, force: false)
      assert timestamp > 0
      assert config_file == "config_file"
      assert files == ["file1", "file2"]

      now = System.system_time(:second)
      assert_in_delta timestamp, now, 3
    end

    test "returns manifest without files" do
      File.write!(manifest(), "config_file")

      assert {timestamp, config_file, files} = Manifest.read(manifest: true, force: false)
      assert timestamp > 0
      assert config_file == "config_file"
      assert Enum.empty?(files)
    end

    test "returns nil if manifest: false" do
      File.write!(manifest(), "config_file")

      assert Manifest.read(manifest: false, force: false) == nil
    end

    test "returns nil if force: true" do
      File.write!(manifest(), "config_file")

      assert Manifest.read(manifest: true, force: true) == nil
    end

    test "returns nil if no manifest exists" do
      File.rm(manifest())

      assert Manifest.read(manifest: true, force: false) == nil
    end

    test "returns nil and prints error for an invalid manifest" do
      File.write!(manifest(), "")

      output =
        capture_io(:stderr, fn ->
          assert Manifest.read(manifest: true, force: false) == nil
        end)

      assert output =~ "Failed to read manifest: invalid content"
    end

    test "returns nil and prints error for an unreadable file" do
      File.write!(manifest(), "config")
      File.chmod!(manifest(), 0o333)

      output =
        capture_io(:stderr, fn ->
          assert Manifest.read(manifest: true, force: false) == nil
        end)

      assert output =~ "Failed to read manifest:"
    end
  end

  describe "write/2" do
    test "writes manifest" do
      project = Rewrite.new()

      assert Manifest.write(project, manifest: true) == :ok
      assert File.read!(manifest()) == ".recode.exs"
    end

    test "write manifest for config" do
      project = Rewrite.new()

      assert Manifest.write(project, manifest: true, cli_opts: [config_file: "config.exs"]) == :ok
      assert File.read!(manifest()) == "config.exs"
    end

    test "does not write manifest" do
      project = Rewrite.new()

      assert Manifest.write(project, manifest: false) == :ok
      refute File.exists?(manifest())
    end

    test "writes no file list in manifest" do
      {:ok, project} =
        Rewrite.from_sources([
          Rewrite.Source.from_string("", path: "foo.ex")
        ])

      assert Manifest.write(project, manifest: true) == :ok
      assert File.read!(manifest()) == ".recode.exs"
    end

    test "writes file list for sources with issue" do
      opts = [manifest: true]

      {:ok, project} =
        Rewrite.from_sources([
          "" |> Source.from_string(path: "foo.ex") |> Source.add_issue("foo"),
          "" |> Source.from_string(path: "bar.ex") |> Source.update(:content, "bar"),
          Source.from_string("", path: "baz.ex")
        ])

      assert Manifest.write(project, opts) == :ok
      assert File.read!(manifest()) == ".recode.exs\nfoo.ex"
    end

    test "writes file list for sources with issue or updates" do
      opts = [manifest: true, dry: true]

      {:ok, project} =
        Rewrite.from_sources([
          "" |> Source.from_string(path: "foo.ex") |> Source.add_issue("foo"),
          "" |> Source.from_string(path: "bar.ex") |> Source.update(:content, "bar"),
          Source.from_string("", path: "baz.ex")
        ])

      assert Manifest.write(project, opts) == :ok
      assert File.read!(manifest()) == ".recode.exs\nfoo.ex\nbar.ex"
    end

    test "prints error if file cannot be written" do
      File.write(manifest(), "")
      File.chmod!(manifest(), 0o444)

      project = Rewrite.new()

      output =
        capture_io(:stderr, fn ->
          assert Manifest.write(project, manifest: true) == :ok
        end)

      assert output =~ "Failed to write manifest: permission denied"
    end
  end

  defp manifest, do: Path.join(Mix.Project.manifest_path(), @manifest_file)
end
