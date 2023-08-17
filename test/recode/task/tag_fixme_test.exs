defmodule Recode.Task.TagFIXMETest do
  use RecodeCase

  alias Recode.Task.TagFIXME

  describe "run/1" do
    #
    # cases NOT raising issues
    #

    test "does not trigger" do
      ~s'''
      defmodule FIXME do
        @moduledoc """
        The FIXME module
        """

        # Returns FIXME atom
        def todo(x), do: :FIXME
      end
      '''
      |> run_task(TagFIXME)
      |> refute_issues()
    end

    test "does not triggers tags in doc when deactivated" do
      ~s'''
      defmodule FIXME do
        @moduledoc """
        The FIXME module
        FIXME add examples
        """

        def todo(x), do: :FIXME
      end
      '''
      |> run_task(TagFIXME, include_docs: false)
      |> refute_issues()
    end

    #
    # cases NOT raising issues
    #

    test "triggers an issue for a tag in comment" do
      ~s'''
      defmodule FIXME do
        @moduledoc """
        The FIXME module
        """

        # FIXME: add spec
        def todo(x), do: :FIXME
      end
      '''
      |> run_task(TagFIXME)
      |> assert_issue_with(
        reporter: TagFIXME,
        line: 6,
        message: "Found a tag: FIXME: add spec"
      )
    end
  end

  describe "init/1" do
    test "returns an ok tuple with added defaults" do
      assert TagFIXME.init(tag: "FIXME", reporter: TagFIXME) ==
               {:ok, include_docs: true, tag: "FIXME", reporter: TagFIXME}
    end

    test "returns an ok tuple" do
      assert TagFIXME.init(tag: "FIXME", reporter: TagFIXME, include_docs: false) ==
               {:ok, tag: "FIXME", reporter: TagFIXME, include_docs: false}
    end
  end
end
