defmodule AshCloak.Test.Vault do
  @moduledoc false
  def encrypt!(value) when is_binary(value), do: "encrypted #{value}"

  def decrypt!("encrypted " <> value), do: value
end
