defmodule RecodeCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Rewrite.Project
  alias Rewrite.Source

  using do
    quote do
      import RecodeCase
    end
  end

  setup context do
    Mox.stub_with(Recode.RunnerMock, Recode.Runner.Impl)

    context
  end

  def assert_issue(%Source{} = source, reporter) do
    assert_issues(source, reporter, 1)
  end

  def assert_issues(%Source{issues: issues}, reporter, amount) do
    assert length(issues) == amount,
           "Expected #{amount} issue(s), got: #{inspect(issues, pretty: true)}"

    assert Enum.any?(issues, fn {_version, issue} -> issue.reporter == reporter end),
           """
           Expected that each issue was reported by #{inspect(reporter)}, \
           got: #{inspect(issues, pretty: true)}\
           """
  end

  def assert_no_issues(%Source{issues: issues}) do
    assert issues == [], "Expected no issues, got #{inspect(issues, pretty: true)}"
  end

  defmacro assert_code({:==, _meta, [source, expected]}) do
    quote bind_quoted: [source: source, expected: expected] do
      assert source |> Source.code() |> eof_newline() == eof_newline(expected)
    end
  end

  def source(string, path \\ nil) do
    if File.exists?(string) do
      Source.read!(string)
    else
      Source.from_string(string, path)
    end
  end

  def project(%Source{} = source) do
    Project.from_sources([source])
  end

  def run_task(%Source{} = source, {task, opts}) do
    task.run(source, opts)
  end

  def formated?(code) do
    String.trim(code) == code |> Code.format_string!() |> IO.iodata_to_binary()
  end

  def eof_newline(string), do: String.trim_trailing(string) <> "\n"
end
