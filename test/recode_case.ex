defmodule RecodeCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Recode.Project

  using do
    quote do
      # def run_task(task, opts \\ [], input)

      # def run_task(task, opts, source) when is_binary(source) do
      #   source
      #   |> RecodeCase.eval()
      #   |> Sourceror.parse_string!()
      #   |> task.run(opts)
      #   |> Sourceror.to_string()
      # end

      def run_task(task, config, opts) do
        project = Project.new(config[:inputs])
        task.run(project, opts)
      end

      # def run_task(task, opts, file: file) do
      #   file
      #   |> RecodeCase.eval()
      #   |> Sourceror.parse_string!()
      #   |> task.run(Keyword.put(opts, :project, Recode.ProjectOld.new([file])))
      #   |> Sourceror.to_string()
      # end

      # def run_task(task, opts, string) when is_binary(string) do
      #   string
      #   |> Sourceror.parse_string!()
      #   |> task.run(opts)
      #   |> Sourceror.to_string()
      # end

      # def run_task(task, opts \\ [], params)

      # def run_task(task, opts, string) when is_binary(string) do
      #   string
      #   |> Sourceror.parse_string!()
      #   |> task.run(opts)
      #   |> Sourceror.to_string()
      # end

      # def run_task(task, opts, params) when is_list(params) do
      #   params
      #   |> Keyword.fetch!(:path)
      #   |> read()
      #   |> Enum.into(%{}, fn {file, code} ->
      #     {file, run_task(task, opts, code)}
      #   end)
      # end

      # def read(path) do
      #   path
      #   |> Path.join("**/*.ex")
      #   |> Path.wildcard()
      #   |> Enum.into(%{}, fn file ->
      #     {String.replace_leading(file, path, ""), File.read!(file)}
      #   end)
      # end

      # def assert_files(files, expected) do
      #   Enum.each(files, fn {name, content} ->
      #     expected_content = expected |> Map.get(name) |> RecodeCase.trim_trailing()
      #     assert {name, content} == {name, expected_content}
      #   end)
      # end
    end
  end

  def eval(file) do
    source = File.read!(file)
    Code.eval_string(source, file: file)
    source
  end

  def trim_trailing(nil), do: nil
  def trim_trailing(string), do: String.trim_trailing(string)
end
