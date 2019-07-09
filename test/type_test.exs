defmodule ArcTest.Ecto.Paperclip.Type do
  use ExUnit.Case, async: false

  test "dumps files" do
    {:ok, value} = DummyDefinition.Type.dump("file.png")
    assert value == "file.png"
  end

  test "loads file" do
    {:ok, value} = DummyDefinition.Type.load("file.png")
    assert value == "file.png"
  end
end
