defmodule Arc.Ecto.Paperclip.Interpolations do
  @doc """
    Paperclip default interpolation of class name... Example: Book -> books
  """
  @spec class(struct, atom, atom) :: {String.t}
  def class(scope, _attachment_name, _version \\ :original) do
    scope.__struct__ |> Inflex.pluralize |> Macro.underscore |> String.split("/") |> List.last
  end

  @doc """
    Paperclip default interpolation of attachment name... Example: :book -> books
  """
  @spec attachment(struct, atom, atom) :: {String.t}
  def attachment(_scope, attachment_name, _version \\ :original) do
    Atom.to_string(attachment_name) |> Inflex.pluralize
  end

  @doc """
    Paperclip default interpolation of id_partition. Calculated using the objects ID
  """
  @spec id_partition(struct, atom, atom) :: {String.t}
  def id_partition(scope, _attachment_name, _version \\ :original) do
    String.pad_leading("#{scope.id}", 9, "0")
    |> String.split(~r/\d{3}/, include_captures: true, trim: true)
    |> Enum.take(3)
    |> Enum.map(fn s -> String.slice(s, 0, 3) end) # Fixes uuid support
    |> Enum.join("/")
  end

  @doc """
    Paperclip default interpolation of style
  """
  @spec style(struct, atom, atom) :: {String.t}
  def style(_scope, _attachment_name, version \\ :original) do
    Atom.to_string(version)
  end

  @doc """
    Paperclip style filename of the attachment
  """
  @spec filename(struct, atom, atom) :: {String.t}
  def filename(scope, attachment_name, _version \\ :original) do
    Map.get(scope, String.to_atom("#{attachment_name}_file_name"))
  end
end
