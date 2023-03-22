defmodule Mix.Tasks.FormatterPluginTest do
  use RecodeCase

  import Mox

  alias Recode.FormatterPlugin
  alias Recode.RunnerMock
  alias Recode.Task.SinglePipe

  setup :verify_on_exit!

  test "returns features" do
    assert FormatterPlugin.features(recode: [tasks: []]) == [extensions: [".ex", ".exs"]]
  end

  test "raises an error for missing tasks key" do
    assert_raise Mix.Error, "No `:tasks` key found in configuration.", fn ->
      FormatterPlugin.features(recode: [])
    end
  end

  test "adsf" do
    expect(RunnerMock, :run, fn content, config, path ->
      assert content == "code"
      assert path == "source.ex"

      assert config == [
               dot_formatter_opts: [locals_without_parens: [foo: 2], plugins: []],
               tasks: [{Recode.Task.SinglePipe, []}],
               dry: false,
               verbose: false,
               autocorrect: true,
               check: false
             ]

      :ok
    end)

    FormatterPlugin.features(recode: [tasks: [{SinglePipe, []}]])

    # assert catch_exit(Tasks.Recode.run(["--config", "priv/config.exs", "--dry"])) == :normal
    assert FormatterPlugin.format("code", locals_without_parens: [foo: 2]) == :ok
  end
end
