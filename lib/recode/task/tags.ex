defmodule Recode.Task.Tags do
  @moduledoc false

  use Recode.Task, category: :design

  alias Recode.Issue
  alias Rewrite.Source
  alias Sourceror.Zipper

  @defaults include_docs: true

  @impl Recode.Task
  def run(source, opts) do
    source
    |> Source.get(:quoted)
    |> Zipper.zip()
    |> Zipper.traverse([], fn zipper, issues ->
      check_tags(zipper, issues, opts)
    end)
    |> update(source)
  end

  @impl Recode.Task
  def init(opts) do
    cond do
      not Keyword.has_key?(opts, :tag) ->
        {:error,
         """
         Recode.Task.Tags needs a configuration entry for :tag (e.g. tag: "TODO")\
         """}

      not Keyword.has_key?(opts, :reporter) ->
        {:error,
         """
         Recode.Task.Tags needs a configuration entry for :reporter \
         (e.g. reporter: "Recode.Task.TagTODO")\
         """}

      true ->
        {:ok, Keyword.merge(@defaults, opts)}
    end
  end

  defp update({_zipper, issues}, source) do
    Source.add_issues(source, issues)
  end

  defp check_tags(%Zipper{node: {doc, _meta, args}} = zipper, issues, opts)
       when doc in [:moduledoc, :doc, :shortdoc] do
    issues =
      if opts[:include_docs] && doc?(args) do
        args
        |> doc()
        |> find_tags(opts)
        |> Enum.concat(issues)
      else
        issues
      end

    {zipper, issues}
  end

  defp check_tags(%Zipper{node: {_op, meta, _args}} = zipper, issues, opts) do
    issues =
      meta
      |> comments()
      |> Enum.flat_map(fn comment -> find_tags(comment, opts) end)
      |> Enum.concat(issues)

    {zipper, issues}
  end

  defp check_tags(zipper, issues, _opts), do: {zipper, issues}

  defp doc?([{:__block__, _meta, [text]}]), do: text != false

  defp doc?(_expr), do: false

  defp doc([{:__block__, meta, [text]}]) do
    doc = Keyword.put(meta, :text, text)

    case String.length(doc[:delimiter] || "") do
      3 -> Keyword.update!(doc, :line, fn line -> line + 1 end)
      _ -> doc
    end
  end

  defp comments(meta) do
    Keyword.get(meta, :leading_comments, []) ++ Keyword.get(meta, :trailing_comments, [])
  end

  defp find_tags(meta, opts) when is_map(meta) do
    find_tags(Enum.into(meta, []), opts)
  end

  defp find_tags(meta, opts) do
    meta
    |> Keyword.get(:text, "")
    |> String.split("\n")
    |> find_tags(~r/^#?\s*#{opts[:tag]}/, 0, [])
    |> issues(meta, opts)
  end

  defp find_tags([], _regex, _line_number, acc), do: acc

  defp find_tags([line | lines], regex, line_number, acc) do
    case Regex.match?(regex, line) do
      true -> find_tags(lines, regex, line_number + 1, [{line_number, line} | acc])
      false -> find_tags(lines, regex, line_number + 1, acc)
    end
  end

  defp issues(tags, meta, opts) do
    Enum.map(tags, fn {line, text} ->
      text = Regex.replace(~r/^[#\s]*/, text, "")
      Issue.new(opts[:reporter], "Found a tag: #{text}", line: line + meta[:line])
    end)
  end
end
