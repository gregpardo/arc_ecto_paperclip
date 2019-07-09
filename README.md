Arc.Ecto.Paperclip
========

Arc.Ecto.Paperclip is a library based on [Arc.Ecto](https://github.com/stavro/arc_ecto) 
with a goal of supporting traditional rails paperclip model columns. 
This is useful when you want to run an elixir application and rails application against the same database schema
or if you are planning on migrating to elixir eventually. 

Installation
============

Add the latest stable release to your `mix.exs` file:

```elixir
defp deps do
  [
    {:arc_ecto_paperclip, "~> 0.1.0"}
  ]
end
```

Then run `mix deps.get` in your shell to fetch the dependencies.

Usage
=====

### Add Arc.Ecto.Paperclip.Definition

Add a second using macro `use Arc.Ecto.Paperclip.Definition` to the top of your Arc definitions.

```elixir
defmodule MyApp.Avatar do
  use Arc.Definition
  use Arc.Ecto.Paperclip.Definition

  # ...
end
```

### Add a string column to your schema

Arc paperclip like attachments should be stored in a set of columns like so.

```elixir
create table :users do
  add :avatar_file_name, :string
  add :avatar_file_size, :integer
  add :avatar_content_type, :string
  add :avatar_updated_at, :datetime
end
```

### Add your attachment to your Ecto Schema

Add a using statement `use Arc.Ecto.Schema` to the top of your ecto schema, and specify the type of the column in your schema as `MyApp.Avatar.Type`.

Attachments can subsequently be passed to Arc's storage though a Changeset `cast_paperclip/3` function, following the syntax of `cast/3`

Notice the attachment macro that generates the appropriate fields for the schema given attachment name.

```elixir
defmodule MyApp.User do
  use MyApp.Web, :model
  use Arc.Ecto.Paperclip.Schema

  schema "users" do
    field :name,   :string
    attachment :avatar, MyApp.Avatar.Type
  end

  @doc """
  Creates a changeset based on the `data` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(user, params \\ :invalid) do
    user
    |> cast(params, [:name])
    |> cast_paperclip(params, [:avatar])
    |> validate_required([:name, :avatar_file_name])
  end
end
```

Also notice that when validating required, you should use the actual `avatar_file_name` field instead of the attachment field name. 

### Save your attachments as normal through your controller

```elixir
  @doc """
  Given params of:

  %{
    "id" => 1,
    "user" => %{
      "avatar" => %Plug.Upload{
                    content_type: "image/png",
                    filename: "selfie.png",
                    path: "/var/folders/q0/dg42x390000gp/T//plug-1434/multipart-765369-5"}
    }
  }

  """
  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Repo.get(User, id)
    changeset = User.changeset(user, user_params)

    if changeset.valid? do
      Repo.update(changeset)

      conn
      |> put_flash(:info, "User updated successfully.")
      |> redirect(to: user_path(conn, :index))
    else
      render conn, "edit.html", user: user, changeset: changeset
    end
  end
```

### Retrieve the serialized url

Both public and signed urls will include the timestamp for cache busting, and are retrieved the exact same way as using Arc directly.

```elixir
  user = Repo.get(User, 1)

  # To receive a single rendition:
  MyApp.Avatar.url({user.avatar, user}, :thumb)
    #=> "https://bucket.s3.amazonaws.com/uploads/avatars/1/thumb.png?v=63601457477"

  # To receive all renditions:
  MyApp.Avatar.urls({user.avatar, user})
    #=> %{original: "https://.../original.png?v=1234", thumb: "https://.../thumb.png?v=1234"}

  # To receive a signed url:
  MyApp.Avatar.url({user.avatar, user}, signed: true)
  MyApp.Avatar.url({user.avatar, user}, :thumb, signed: true)
```

## License

Copyright 2019 Greg Pardo

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
