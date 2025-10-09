# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.Vault do
  @moduledoc false
  def encrypt!(value) when is_binary(value), do: "encrypted #{value}"

  def decrypt!("encrypted " <> value), do: value
end
