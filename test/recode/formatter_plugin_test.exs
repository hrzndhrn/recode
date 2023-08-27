defmodule Recode.FormatterPluginTest do
  use RecodeCase, async: false

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

  test "raises an error for missing config" do
    message = """
    No configuration for `Recode.FormatterPlugin` found. Run `mix recode.get.config` \
    to create a config file or add config in `.formatter.exs` under the key `:recode`.
    """

    assert_raise Mix.Error, message, fn ->
      FormatterPlugin.features([])
    end
  end

  test "runs with tasks from the .formatter config" do
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

    assert FormatterPlugin.format("code", locals_without_parens: [foo: 2]) == :ok
  end

  test "removes the FormatterPlugin from plugins" do
    expect(RunnerMock, :run, fn content, config, path ->
      assert content == "code"
      assert path == "source.ex"

      assert config == [
               dot_formatter_opts: [locals_without_parens: [foo: 2], plugins: [FreedomFormatter]],
               tasks: [{Recode.Task.SinglePipe, []}],
               dry: false,
               verbose: false,
               autocorrect: true,
               check: false
             ]

      :ok
    end)

    FormatterPlugin.features(recode: [tasks: [{SinglePipe, []}]])

    assert FormatterPlugin.format("code",
             locals_without_parens: [foo: 2],
             plugins: [FreedomFormatter, Recode.FormatterPlugin]
           )
  end

  @tag :tmp_dir
  test "formats files", %{tmp_dir: dir} do
    File.cd!(dir, fn ->
      File.mkdir!("lib")

      File.write!(".recode.exs", """
      [
        autocorrect: true,
        dry: false,
        verbose: false,
        inputs: ["{config,lib,test}/**/*.{ex,exs}"],
        formatters: [Recode.CLIFormatter],
        tasks: [
          {Recode.Task.SinglePipe, []},
          {Recode.Task.PipeFunOne, []},
          {Recode.Task.AliasExpansion, []}
        ]
      ]
      """)

      path = "lib/foo.ex"

      code = """
      defmodule Foo do
      def foo, do: :foo
      end
      """

      File.write!(path, code)

      FormatterPlugin.features([])

      assert FormatterPlugin.format(code, file: path, plugins: [Recode.FormatterPlugin]) == """
             defmodule Foo do
               def foo, do: :foo
             end
             """
    end)
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

      assert_raise Mix.Error, message, fn -> FormatterPlugin.features([]) end
    end)
  end
end
