defmodule Recode.ManifestTest do
  use RecodeCase, async: false

  import ExUnit.CaptureIO

  alias Recode.Manifest
  alias Rewrite.Source

  @manifest_file "recode.issues"

  setup do
    [project: TestProject.new()]
  end

  @moduletag :tmp_dir

  describe "read/1" do
    test "returns manifest", context do
      in_tmp context do
        File.mkdir_p(Mix.Project.manifest_path())

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
    end

    test "returns manifest without files", context do
      in_tmp context do
        File.mkdir_p(Mix.Project.manifest_path())
        File.write!(manifest(), "config_file")

        assert {timestamp, config_file, files} = Manifest.read(manifest: true, force: false)
        assert timestamp > 0
        assert config_file == "config_file"
        assert Enum.empty?(files)
      end
    end

    test "returns nil if manifest: false", context do
      in_tmp context do
        File.mkdir_p(Mix.Project.manifest_path())
        File.write!(manifest(), "config_file")

        assert Manifest.read(manifest: false, force: false) == nil
      end
    end

    test "returns nil if force: true", context do
      in_tmp context do
        File.mkdir_p(Mix.Project.manifest_path())
        File.write!(manifest(), "config_file")

        assert Manifest.read(manifest: true, force: true) == nil
      end
    end

    test "returns nil if no manifest exists", context do
      in_tmp context do
        assert Manifest.read(manifest: true, force: false) == nil
      end
    end

    test "returns nil and prints error for an invalid manifest", context do
      in_tmp context do
        File.mkdir_p(Mix.Project.manifest_path())
        File.write!(manifest(), "")

        capture_io(:stdio, fn ->
          output =
            capture_io(:stderr, fn ->
              assert Manifest.read(manifest: true, force: false) == nil
            end)

          assert output =~ "Failed to read manifest: invalid content"
        end)
      end
    end

    test "returns nil and prints error for an unreadable file", context do
      in_tmp context do
        File.mkdir_p(Mix.Project.manifest_path())
        File.write!(manifest(), "config")
        File.chmod!(manifest(), 0o333)

        capture_io(:stdio, fn ->
          output =
            capture_io(:stderr, fn ->
              assert Manifest.read(manifest: true, force: false) == nil
            end)

          assert output =~ "Failed to read manifest:"
        end)
      end
    end
  end

  describe "write/2" do
    test "writes manifest", context do
      in_tmp context do
        project = Rewrite.new()

        assert Manifest.write(project, manifest: true) == :ok
        assert File.read!(manifest()) == ".recode.exs"
      end
    end

    test "write manifest for config", context do
      in_tmp context do
        project = Rewrite.new()

        assert Manifest.write(
                 project,
                 manifest: true,
                 cli_opts: [config_file: "config.exs"]
               ) ==
                 :ok

        assert File.read!(manifest()) == "config.exs"
      end
    end

    test "does not write manifest", context do
      in_tmp context do
        project = Rewrite.new()

        assert Manifest.write(project, manifest: false) == :ok
        refute File.exists?(manifest())
      end
    end

    test "writes no file list in manifest", context do
      in_tmp context do
        {:ok, project} =
          Rewrite.from_sources([
            Rewrite.Source.from_string("", path: "foo.ex")
          ])

        assert Manifest.write(project, manifest: true) == :ok
        assert File.read!(manifest()) == ".recode.exs"
      end
    end

    test "writes file list for sources with issue", context do
      in_tmp context do
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
    end

    test "writes file list for sources with issue or updates", context do
      in_tmp context do
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
    end

    test "prints error if file cannot be written", context do
      in_tmp context do
        File.mkdir_p(Mix.Project.manifest_path())
        File.write(manifest(), "")
        File.chmod!(manifest(), 0o444)

        project = Rewrite.new()

        capture_io(:stdio, fn ->
          output =
            capture_io(:stderr, fn ->
              assert Manifest.write(project, manifest: true) == :ok
            end)

          assert output =~ "Failed to write manifest: permission denied"
        end)
      end
    end
  end

  defp manifest, do: Path.join(Mix.Project.manifest_path(), @manifest_file)
end
