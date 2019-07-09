defmodule DummyDefinitionTwo do
  def url(_, :original, _), do: "fallback"
  def store({file, _}), do: {:ok, file}
  def delete(_), do: :ok
  defoverridable [delete: 1, url: 3]
  use Arc.Ecto.Paperclip.Definition
end
