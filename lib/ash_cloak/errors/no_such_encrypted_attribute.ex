defmodule AshCloak.Errors.NoSuchEncryptedAttribute do
  @moduledoc """
  An error raised when attempting to decrypt an attribute that is not encrypted.
  """

  use Splode.Error, fields: [:key, :resource], class: :invalid

  def message(error) do
    """
    Attempted to encrypt and set attribute#{for_key(error)}#{for_resource(error)}, but it is not configured for encryption.}
    """
  end

  defp for_key(%{key: key}) when not is_nil(key), do: " for #{key}"
  defp for_key(_), do: ""

  defp for_resource(%{resource: resource}) when not is_nil(resource), do: " for #{resource}"
  defp for_resource(_), do: ""
end
