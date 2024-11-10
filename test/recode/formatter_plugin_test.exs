defmodule Recode.FormatterPluginTest do
  use RecodeCase, async: false

  import Mox

  alias Recode.FormatterPlugin
  alias Recode.RunnerMock
  alias Recode.Task.SinglePipe

  setup :verify_on_exit!

  setup do
    _erase = :persistent_term.erase({Recode.FormatterPlugin, :config})
    :ok
  end

  test "returns features" do
    assert FormatterPlugin.features(recode: [tasks: []]) == [extensions: [".ex", ".exs"]]
  end

  test "runs with tasks from the .formatter config" do
    expect(RunnerMock, :run, fn content, config, path ->
      assert content == "code"
      assert path == "source.ex"

      assert config == [
               formatter_opts: [
                 locals_without_parens: [foo: 2],
                 recode: [tasks: [{SinglePipe, []}]]
               ],
               tasks: [{Recode.Task.SinglePipe, []}],
               dry: false,
               verbose: false,
               autocorrect: true,
               check: false
             ]

      :ok
    end)

    formatter_opts = [
      locals_without_parens: [foo: 2],
      recode: [tasks: [{SinglePipe, []}]]
    ]

    assert FormatterPlugin.format("code", formatter_opts) == :ok
  end

  test "raises an error for missing tasks key" do
    assert_raise Mix.Error, "No `:tasks` key found in configuration.", fn ->
      FormatterPlugin.format("", recode: [])
    end
  end

  test "raises an error for missing config" do
    message = """
    No configuration for `Recode.FormatterPlugin` found. Run `mix recode.gen.config` \
    to create a config file or add config in `.formatter.exs` under the key `:recode`.
    """

    assert_raise Mix.Error, message, fn ->
      FormatterPlugin.format("", [])
    end
  end

  @tag :tmp_dir
  test "throws an exception for an outdated config", %{tmp_dir: dir} do
    File.cd!(dir, fn ->
      File.write!(".recode.exs", """
        [
          version: "0.0.0",
          tasks: [ {Recode.Task.SinglePipe, []} ]
        ]
      """)

      message = "The config is out of date. Run `mix recode.update.config` to update."

      assert_raise Mix.Error, message, fn -> FormatterPlugin.format("", []) end
    end)
  end
end
