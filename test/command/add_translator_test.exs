defmodule Walybot.Command.AddTranslatorTest do
  use ExUnit.Case, async: true
  alias Walybot.Command.AddTranslator

  test "parsing a valid username" do
    assert AddTranslator.parse_username("/addtranslator @rick") == {:ok, "rick"}
  end
end
