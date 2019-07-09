defmodule Arc.Ecto.Paperclip.Type do
  @moduledoc false
  require Logger

  def type, do: :string

  def cast(definition, file) do
    case definition.store(file) do
      {:ok, file} -> {:ok, file}
      error ->
        Logger.error(inspect(error))
        :error
    end
  end

  def load(_definition, file) do
    {:ok, file}
  end

  def dump(_definition, file) do
    {:ok, file}
  end
end
