# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.BatchVault do
  @moduledoc false
  # A vault that can decrypt a batch. Every call is reported to the calling process (and to
  # the process that started it, when the calculation runs in a task), so a test can tell
  # one batch call from one call per value.

  def encrypt!(value) when is_binary(value), do: "encrypted #{value}"

  def decrypt!("encrypted " <> value = ciphertext) do
    report({:decrypt, ciphertext})
    value
  end

  def decrypt_many!(ciphertexts) do
    report({:decrypt_many, ciphertexts})
    Enum.map(ciphertexts, fn "encrypted " <> value -> value end)
  end

  defp report(message) do
    for pid <- [self() | Process.get(:"$callers", [])], do: send(pid, message)
  end
end

defmodule AshCloak.Test.ShortBatchVault do
  @moduledoc false
  # A broken vault: its batch answer is one plaintext short.

  def encrypt!(value) when is_binary(value), do: "encrypted #{value}"

  def decrypt!("encrypted " <> value), do: value

  def decrypt_many!(ciphertexts) do
    ciphertexts
    |> Enum.drop(1)
    |> Enum.map(fn "encrypted " <> value -> value end)
  end
end

defmodule AshCloak.Test.BatchVaultSelector do
  @moduledoc false
  def select(_resource, nil), do: AshCloak.Test.BatchVault

  def select(_resource, context) do
    case Map.get(context, :source_context, %{}) do
      %{test_vault: :short} -> AshCloak.Test.ShortBatchVault
      _ -> AshCloak.Test.BatchVault
    end
  end
end

defmodule AshCloak.Test.BatchResource do
  @moduledoc false

  use Ash.Resource,
    domain: AshCloak.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshCloak]

  ets do
    private?(true)
  end

  actions do
    defaults([:read, :destroy, create: [:position, :encrypted]])
  end

  cloak do
    vault({AshCloak.Test.BatchVaultSelector, :select, []})
    attributes([:encrypted])
    encrypt_nil?(false)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:position, :integer, public?: true)
    # nullable, and stored as NULL when nil, so a batch can hold a value with nothing to decrypt
    attribute(:encrypted, :integer, public?: true)
  end
end
