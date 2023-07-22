defmodule RecodeCase do
  @moduledoc false

  use ExUnit.CaseTemplate

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

  defmacro assert_issue(source) do
    quote bind_quoted: [source: source] do
      assert length(source.issues) == 1,
             "Expected one issue, got:\n#{inspect(source.issues, pretty: true)}"
    end
  end

  defmacro assert_issue_with(source, keyword) do
    quote bind_quoted: [source: source, keyword: keyword] do
      assert length(source.issues) == 1,
             "Expected one issue, got:\n#{inspect(source.issues, pretty: true)}"

      {_, issue} = hd(source.issues)

      Enum.each(keyword, fn {key, value} ->
        got = Map.fetch!(issue, key)

        assert got == value,
               "Expected #{inspect(value)} for #{inspect(key)} in issue, got: #{inspect(got)}"
      end)
    end
  end

  @deprected "refactor"
  def assert_issue(%Source{} = source, reporter) do
    assert_issues(source, reporter, 1)
  end

  @deprected "refactor"
  def assert_issues(%Source{issues: issues}, reporter, amount) do
    assert length(issues) == amount,
           "Expected #{amount} issue(s), got: #{inspect(issues, pretty: true)}"

    assert Enum.any?(issues, fn {_version, issue} -> issue.reporter == reporter end),
           """
           Expected that each issue was reported by #{inspect(reporter)}, \
           got: #{inspect(issues, pretty: true)}\
           """
  end

  @deprecated "use refute_issues/1"
  def assert_no_issues(%Source{issues: issues}) do
    assert issues == [], "Expected no issues, got #{inspect(issues, pretty: true)}"
  end

  defmacro refute_issues(source) do
    quote bind_quoted: [source: source] do
      assert Enum.empty?(source.issues),
             "Expected no issues, got #{inspect(source.issues, pretty: true)}"
    end
  end

  defmacro refute_update(source) do
    quote bind_quoted: [source: source] do
      refute Source.updated?(source)
    end
  end

  @deprecated "use assert_code/2"
  defmacro assert_code({:==, _meta, [source, expected]}) do
    quote bind_quoted: [source: source, expected: expected] do
      assert source |> Source.get(:content) |> eof_newline() == eof_newline(expected)
    end
  end

  defmacro assert_code(source, expected) do
    quote bind_quoted: [source: source, expected: expected] do
      assert Source.get(source, :content) == expected
    end
  end

  def source(string, path \\ nil) do
    Source.Ex.from_string(string, path)
  end

  def project(%Source{} = source) do
    Rewrite.from_sources!([source])
  end

  @deprecated "use run_task/3"
  def run_task(code, {task, opts}) when is_binary(code) do
    code
    |> Source.Ex.from_string()
    |> task.run(opts)
  end

  @deprecated "use run_task/3"
  def run_task(%Source{} = source, {task, opts}) do
    task.run(source, opts)
  end

  def run_task(code, task, opts) when is_binary(code) do
    code
    |> Source.Ex.from_string()
    |> task.run(opts)
  end

  def formated?(code) do
    String.trim(code) == code |> Code.format_string!() |> IO.iodata_to_binary()
  end

  def eof_newline(string), do: String.trim_trailing(string) <> "\n"
end
