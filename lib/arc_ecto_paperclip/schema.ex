defmodule Arc.Ecto.Paperclip.Schema do
  defmacro __using__(_) do
    quote do
      import Arc.Ecto.Paperclip.Schema
    end
  end

  # No current supported options yet
  defmacro attachment(name, type, opts \\ []) do
    quote do
      Ecto.Schema.__field__(__MODULE__, String.to_atom("#{unquote(name)}_file_name"), :string, unquote(opts))
      Ecto.Schema.__field__(__MODULE__, String.to_atom("#{unquote(name)}_file_size"), :integer, unquote(opts))
      Ecto.Schema.__field__(__MODULE__, String.to_atom("#{unquote(name)}_content_type"), :string, unquote(opts))
      Ecto.Schema.__field__(__MODULE__, String.to_atom("#{unquote(name)}_updated_at"), :utc_datetime, unquote(opts))
      Ecto.Schema.__field__(__MODULE__, String.to_atom("#{unquote(name)}_upload"), unquote(type), unquote(opts))
    end
  end

  # Casting from nil
  def cast_attachment_fields({field, nil}, fields, _, _) do
    cast_attachment_fields(field, %{}, fields)
  end

  # Casting from plug upload
  def cast_attachment_fields({field, upload = %{__struct__: Plug.Upload}}, fields, _, _) do
    values = field_values_local(upload.path)
    values = Map.put(values, :upload, upload)
    cast_attachment_fields(field, values, fields)
  end

  # Casting from url/path
  def cast_attachment_fields({field, path}, fields, options, _) when is_binary(path) do
    cond do
      Keyword.get(options, :allow_urls, false) and Regex.match?( ~r/^https?:\/\// , path) ->
        values = field_values_url(path)
        cast_attachment_fields(field, values, fields)
      Keyword.get(options, :allow_paths, false) ->
        values = field_values_local(path)
        cast_attachment_fields(field, values, fields)
      true ->
        fields
    end
  end

  # Casting once fields are set
  def cast_attachment_fields(field, values, fields) do
    values |> Enum.map(fn {key, value} ->
      { String.to_atom("#{field}_#{key}"), value }
    end) |> Enum.concat(fields)
  end

  def paperclip_expand_allowed(field) do
    [ String.to_atom("#{field}_file_name"),
      String.to_atom("#{field}_file_size"),
      String.to_atom("#{field}_content_type"),
      String.to_atom("#{field}_updated_at"),
      String.to_atom("#{field}_upload") ]
  end

  defmacro cast_paperclip(changeset_or_data, params, allowed, options \\ []) do

    quote bind_quoted: [changeset_or_data: changeset_or_data,
            params: params,
            allowed: allowed,
            options: options] do

      # If given a changeset, apply the changes to obtain the underlying data
      scope = do_apply_changes(changeset_or_data)

      # Cast supports both atom and string keys, ensure we're matching on both.
      allowed_param_keys = Enum.map(allowed, fn key ->
        case key do
          key when is_binary(key) -> key
          key when is_atom(key) -> Atom.to_string(key)
        end
      end)

      # Convert the allowed parameters to the correct database entries
      allowed =
        allowed
        |> Enum.map(&Arc.Ecto.Paperclip.Schema.paperclip_expand_allowed/1)
        |> List.flatten

      arc_params = case params do
        :invalid ->
          :invalid
        %{} ->
          params
          |> Arc.Ecto.Paperclip.Schema.convert_params_to_binary
          |> Map.take(allowed_param_keys)
          |> Enum.reduce([], fn {field, value}, fields ->
            Arc.Ecto.Paperclip.Schema.cast_attachment_fields({field, value}, fields, options, scope)
          end)
          |> Enum.into(%{})
      end

      Ecto.Changeset.cast(changeset_or_data, arc_params, allowed)
    end
  end

  def do_apply_changes(%Ecto.Changeset{} = changeset), do: Ecto.Changeset.apply_changes(changeset)
  def do_apply_changes(%{__meta__: _} = data), do: data

  def convert_params_to_binary(params) do
    Enum.reduce(params, nil, fn
      {key, _value}, nil when is_binary(key) ->
        nil
      {key, _value}, _ when is_binary(key) ->
        raise ArgumentError, "expected params to be a map with atoms or string keys, " <>
                             "got a map with mixed keys: #{inspect params}"
      {key, value}, acc when is_atom(key) ->
        Map.put(acc || %{}, Atom.to_string(key), value)
    end) || params
  end

  # Get attachment field values from local path
  def field_values_local(local_path) do
    %{size: size} = File.stat! local_path
    %{
      file_name: Path.basename(local_path),
      file_size: size,
      content_type: MIME.from_path(local_path),
      updated_at: NaiveDateTime.utc_now,
      upload: local_path
    }
  end

  # Get attachment field values from local or remote url
  def field_values_url(url) do
    response = HTTPoison.head! url
    file_name = URI.parse(url).path |> Path.basename
    %{
      file_name: file_name,
      file_size: header_value(response, ~r/\Content-Length\z/i),
      content_type: header_value(response, ~r/\Content-Type\z/i),
      updated_at: NaiveDateTime.utc_now,
      upload: url
    }
  end

  # Parses an HttpPoison response and returns the value for the header
  defp header_value(response, header_key) do
    {_key, value} =
      Enum.filter(response.headers, fn {key, _} -> String.match?(key, header_key) end)
      |> List.first
    value
  end
end
