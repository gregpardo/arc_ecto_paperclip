defmodule Arc.Ecto.Paperclip.Definition do
  defmacro __using__(_options) do
    definition = __CALLER__.module

    quote do
      defmodule Module.concat(unquote(definition), "Type") do
        @behaviour Ecto.Type
        def type, do: Arc.Ecto.Paperclip.Type.type
        def cast(value), do: Arc.Ecto.Paperclip.Type.cast(unquote(definition), value)
        def load(value), do: Arc.Ecto.Paperclip.Type.load(unquote(definition), value)
        def dump(value), do: Arc.Ecto.Paperclip.Type.dump(unquote(definition), value)
      end
    end
  end

  def url(schema, attachment, options \\ []) do
    updated_at = Map.get(schema, String.to_atom("#{attachment}_updated_at"))
    url = ""
    if options[:timestamp] do
      version_url(updated_at, url)
    else
      url
    end
  end

  defp version_url(updated_at, url) when is_bitstring(updated_at) do
    version_url(NaiveDateTime.from_iso8601!(updated_at), url)
  end

  defp version_url(%NaiveDateTime{} = updated_at, url) do
    stamp = :calendar.datetime_to_gregorian_seconds(NaiveDateTime.to_erl(updated_at))
    case URI.parse(url).query do
      nil -> url <> "?v=#{stamp}"
      _ -> url <> "&v=#{stamp}"
    end
  end

  defp version_url(_, url) do
    url
  end
end
