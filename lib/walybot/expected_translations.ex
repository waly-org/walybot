defmodule Walybot.ExpectedTranslations do
  def init do
    :ets.new(__MODULE__, [:set, :public, :named_table])
  end

  def expect_translation_from(translator, translation) do
    case :ets.insert(__MODULE__, {translator.username, translation}) do
      true -> :ok
      other -> {:error, other}
    end
  end

  def expected_translation(%{username: username}) do
    case :ets.lookup(__MODULE__, username) do
      [{^username, translation}] -> {:ok, translation}
      _ -> {:error, "no translation expected"}
    end
  end

  def clear_expectation(translator) do
    case :ets.delete(__MODULE__, translator.username) do
      true -> :ok
      other -> {:error, other}
    end
  end
end
