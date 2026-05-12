# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.Vault do
  @moduledoc false
  def encrypt!(value) when is_binary(value), do: "encrypted #{value}"

  def decrypt!("encrypted " <> value), do: value
end

defmodule AshCloak.Test.AltVault do
  @moduledoc false
  def encrypt!(value) when is_binary(value), do: "alt_encrypted #{value}"

  def decrypt!("alt_encrypted " <> value), do: value
end
