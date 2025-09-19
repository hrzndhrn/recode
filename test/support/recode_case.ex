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

        error =
          "Expected #{inspect(value)} for key #{inspect(key)} in issue, got: #{inspect(got)}"

        assert got == value, error
      end)
    end
  end

  defmacro assert_issues_with(source, list) do
    quote bind_quoted: [source: source, list: list] do
      assert length(source.issues) == length(list),
             "Expected #{length(list)} issue(s), got:\n#{inspect(source.issues, pretty: true)}"

      for {{_version, issue}, keyword} <- Enum.zip(source.issues, list),
          {key, value} <- keyword do
        got = Map.fetch!(issue, key)

        error =
          "Expected #{inspect(value)} for key #{inspect(key)} in issue, got: #{inspect(got)}"

        assert got == value, error
      end
    end
  end

  defmacro assert_issues(source, amount) do
    quote bind_quoted: [source: source, amount: amount] do
      assert length(source.issues) == amount,
             "Expected #{amount} issue(s), got: #{inspect(source.issues, pretty: true)}"
    end
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

  defmacro assert_code(source, expected) do
    quote bind_quoted: [source: source, expected: expected] do
      assert Source.get(source, :content) == expected
    end
  end

  defmacro assert_path(source, expected) do
    quote bind_quoted: [source: source, expected: expected] do
      assert Source.get(source, :path) == expected
    end
  end

  defmacro assert_config_error(error_tuple, expected_message \\ nil) do
    quote bind_quoted: [error_tuple: error_tuple, expected_message: expected_message] do
      if expected_message do
        assert error_tuple == {:error, expected_message}
      else
        assert {:error, error_message} = error_tuple
        assert is_binary(error_message)
      end
    end
  end

  def source(string, opts \\ [])

  def source(string, path) when is_binary(path) do
    source(string, path: path)
  end

  def source(string, opts) when is_list(opts) do
    Source.Ex.from_string(string, opts)
  end

  def project(%Source{} = source) do
    Rewrite.from_sources!([source])
  end

  def run_task(code, task, opts \\ [])

  def run_task(code, task, opts) when is_binary(code) do
    run_task(Source.Ex.from_string(code), task, opts)
  end

  def run_task(%Source{} = source, task, opts) do
    with {:ok, opts} <- task.init(opts) do
      task.run(source, opts)
    end
  end

  def formated?(code) do
    String.trim(code) == code |> Code.format_string!() |> IO.iodata_to_binary()
  end

  def eof_newline(string), do: String.trim_trailing(string) <> "\n"
end
