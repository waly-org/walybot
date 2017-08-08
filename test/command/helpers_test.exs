defmodule Walybot.Command.HelpersTest do
  use ExUnit.Case, async: true
  alias Walybot.Command.Helpers

  test "parsing a username" do
    assert {:ok, "mmmries"} == Helpers.parse_username("@","@mmmries")
    assert {:error, "please provide a username: @example"} == Helpers.parse_username("@", "derp, burp")
  end
end
