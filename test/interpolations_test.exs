defmodule ArcTest.Ecto.Paperclip.Interpolations do
  use ExUnit.Case, async: false
  alias Arc.Ecto.Paperclip.Interpolations

  defmodule TestUser do
    use Ecto.Schema
    use Arc.Ecto.Paperclip.Schema

    schema "users" do
      field :first_name, :string
      attachment :avatar, DummyDefinition.Type
    end
  end

  test "generates interpolations correctly" do
    user = %TestUser{id: "1dc6255e-30a9-45e1-a35c-43f24343aaa7", avatar_file_name: "avatar.jpeg"} # Random guid
    assert Interpolations.class(user, :avatar) == "test_users"
    assert Interpolations.attachment(user, :avatar) == "avatars"
    assert Interpolations.id_partition(user, :avatar) == "1dc/625/5e-"
    assert Interpolations.style(user, :avatar) == "original"
    assert Interpolations.filename(user, :avatar) == "avatar.jpeg"
  end
end
