defmodule ArcTest.Ecto.Paperclip.Schema do
  use ExUnit.Case, async: false
  import Mock
  import ExUnit.CaptureLog

  defmodule TestUser do
    use Ecto.Schema
    import Ecto.Changeset
    use Arc.Ecto.Paperclip.Schema

    schema "users" do
      field :first_name, :string
      attachment :avatar, DummyDefinition.Type
    end

    def changeset(user, params \\ :invalid) do
      user
      |> cast(params, ~w(first_name)a)
      |> cast_paperclip(params, ~w(avatar)a)
      |> validate_required(:avatar_file_name)
    end

    def path_changeset(user, params \\ :invalid) do
      user
      |> cast(params, ~w(first_name)a)
      |> cast_paperclip(params, ~w(avatar)a, allow_paths: true)
      |> validate_required(:avatar_file_name)
    end

    def url_changeset(user, params \\ :invalid) do
      user
      |> cast(params, ~w(first_name)a)
      |> cast_paperclip(params, ~w(avatar)a, allow_urls: true)
      |> validate_required(:avatar_file_name)
    end

    def changeset2(user, params \\ :invalid) do
      user
      |> cast(params, ~w(first_name)a)
      |> cast_paperclip(params, ~w(avatar)a)
    end
  end

  def build_upload(path) do
    %{__struct__: Plug.Upload, path: path, filename: Path.basename(path)}
  end

  test "supports :invalid changeset" do
    cs = TestUser.changeset(%TestUser{})
    assert cs.valid?   == false
    assert cs.changes  == %{}
    assert cs.errors   == [avatar_file_name: {"can't be blank", [validation: :required]}]
  end

  test "cascades storage success into a valid change" do
    with_mocks([
      {DummyDefinition,
        [],
        [store: fn(path) ->
                  {:ok, path} end]},
      {File, [], [stat!: fn(_) -> %File.Stat{size: 500} end]}
    ]) do
      upload = build_upload("/path/to/my/file.png")
      cs = TestUser.changeset(%TestUser{}, %{"avatar" => upload})
      assert cs.valid?
      assert cs.changes.avatar_file_name == "file.png"
    end
  end

  test "cascades storage error into an error" do
    with_mocks([
      {DummyDefinition,
        [],
        [store: fn(_path) -> {:error, :invalid_file} end]},
      {File, [], [stat!: fn(_) -> %File.Stat{size: 500} end]}
    ]) do
      upload = build_upload("/path/to/my/file.png")
      capture_log(fn ->
        cs = TestUser.changeset(%TestUser{}, %{"avatar" => upload})
        assert called DummyDefinition.store(upload)
        assert cs.valid? == false
        assert cs.errors == [avatar_upload: {"is invalid", [type: DummyDefinition.Type, validation: :cast]}]
      end)
    end
  end

  test "converts changeset into schema" do
    with_mocks([
      {DummyDefinition,
        [],
        [store: fn(_path) -> {:error, :invalid_file} end]},
      {File, [], [stat!: fn(_) -> %File.Stat{size: 500} end]}
    ]) do
      upload = build_upload("/path/to/my/file.png")
      capture_log(fn ->
        TestUser.changeset(%TestUser{}, %{"avatar" => upload})
        assert called DummyDefinition.store(upload)
      end)
    end
  end

  test "applies changes to schema" do
    with_mocks([
      {DummyDefinition,
        [],
        [store: fn(_path) -> {:error, :invalid_file} end]},
      {File, [], [stat!: fn(_) -> %File.Stat{size: 500} end]}
    ]) do
      upload = build_upload("/path/to/my/file.png")
      capture_log(fn ->
        TestUser.changeset(%TestUser{}, %{"avatar" => upload, "first_name" => "test"})
        assert called DummyDefinition.store(upload)
      end)
    end
  end

  test "converts atom keys" do
    with_mocks([
      {DummyDefinition,
        [],
        [store: fn(_path) -> {:error, :invalid_file} end]},
      {File, [], [stat!: fn(_) -> %File.Stat{size: 500} end]}
    ]) do
      upload = build_upload("/path/to/my/file.png")
      capture_log(fn ->
        TestUser.changeset(%TestUser{}, %{avatar: upload})
        assert called DummyDefinition.store(upload)
      end)
    end
  end

  test "casting nil attachments" do
    with_mocks([
      {DummyDefinition,
        [],
        [store: fn(_path) -> {:error, "file.png"} end]},
      {File, [], [stat!: fn(_) -> %File.Stat{size: 500} end]}
    ]) do
      changeset = TestUser.changeset(%TestUser{}, %{"avatar" => build_upload("/path/to/my/file.png")})
      changeset = TestUser.changeset2(changeset, %{"avatar" => nil})
      assert nil == Ecto.Changeset.get_field(changeset, :avatar)
    end
  end

  test "allow_paths => true" do
    with_mocks([
      {DummyDefinition,
        [],
        [store: fn(_path) -> {:ok, "file.png"} end]},
      {File, [], [stat!: fn(_) -> %File.Stat{size: 500} end]}
    ]) do
      cs = TestUser.path_changeset(%TestUser{}, %{"avatar" => "/path/to/my/file.png"})
      assert called DummyDefinition.store("/path/to/my/file.png")
      assert cs.changes.avatar_file_name == "file.png"
      assert cs.changes.avatar_file_size == 500
      assert cs.changes.avatar_content_type == "image/png"
    end
  end

  test "allow_urls => true" do
    with_mocks([
      {DummyDefinition,
        [],
        [store: fn(_path) -> {:ok, "file.png"} end]},
      {File, [], [stat!: fn(_) -> %File.Stat{size: 500} end]},
      {HTTPoison, [], [head!: fn(_) ->
                                %HTTPoison.Response{headers: [
                                                      {"Content-type", "image/png"},
                                                      {"Content-length", "600"}
                                ]}
      end]},
    ]) do
      cs = TestUser.url_changeset(%TestUser{}, %{"avatar" => "http://external.url/file.png"})
      assert called DummyDefinition.store("http://external.url/file.png")
      assert cs.changes.avatar_file_name == "file.png"
      assert cs.changes.avatar_file_size == 600
      assert cs.changes.avatar_content_type == "image/png"
    end
  end

  test "allow_urls => true with an invalid URL" do
    with_mocks([
      {DummyDefinition,
        [],
        [store: fn(_path) -> {:ok, "file.png"} end]},
      {File, [], [stat!: fn(_) -> %File.Stat{size: 500} end]}
    ]) do
      _changeset = TestUser.url_changeset(%TestUser{}, %{"avatar" => "/path/to/my/file.png"})
      assert not called DummyDefinition.store("/path/to/my/file.png")
    end
  end
end
