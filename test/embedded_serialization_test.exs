# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.EmbeddedSerializationTest do
  @moduledoc """
  Reproduces how ash_cloak serializes an encrypted attribute whose type is an
  embedded resource.

  The encryption path serializes the in-memory Elixir struct via
  `:erlang.term_to_binary/1`, instead of going through the type's storage
  representation (`dump_to_native/2`). On read it `binary_to_term`s the struct
  straight back, instead of `cast_stored/2`.
  """
  use ExUnit.Case

  require Ash.Query

  alias AshCloak.Test.{EmbeddedProfile, ResourceWithEmbedded}

  # Mirrors the AshCloak.Test.Vault format: "encrypted " <> term_to_binary, base64-encoded.
  defp decode(value) do
    "encrypted " <> value = Base.decode64!(value)
    Ash.Helpers.non_executable_binary_to_term(value)
  end

  test "the stored ciphertext is the raw struct, not the type's storage representation" do
    record =
      ResourceWithEmbedded
      |> Ash.Changeset.for_create(:create, %{profile: %{nickname: "neo", age: 30}})
      |> Ash.create!()

    stored = decode(record.encrypted_profile)

    # What ash_cloak actually persists: the full in-memory struct, __struct__ tag and all.
    assert is_struct(stored, EmbeddedProfile)
    assert %EmbeddedProfile{nickname: "neo", age: 30} = stored

    # Internal fields that dump_to_native/2 would strip leak into the payload.
    assert Map.has_key?(stored, :__meta__)

    # What an unencrypted embedded attribute would persist (the jsonb the data layer sees):
    # a plain, struct-free map produced by the type's dump_to_native/2.
    {:ok, storage_representation} = Ash.Type.dump_to_native(EmbeddedProfile, stored, [])

    refute is_struct(storage_representation)
    assert is_map(storage_representation)
    refute Map.has_key?(storage_representation, :__meta__)

    # The two diverge: encryption bypasses the storage representation entirely.
    refute stored == storage_representation
  end

  test "decryption restores the struct via binary_to_term, bypassing cast_stored/2" do
    record =
      ResourceWithEmbedded
      |> Ash.Changeset.for_create(:create, %{profile: %{nickname: "trinity", age: 28}})
      |> Ash.create!()

    # Round-trips fine *today* because the same struct is binary_to_term'd back.
    assert %EmbeddedProfile{nickname: "trinity", age: 28} = record.profile

    # But the value never passed through cast_stored/2: it is the exact same term that
    # was term_to_binary'd on write. The module name and struct shape are baked into the
    # blob, so renaming/removing the embedded module, or relying on cast_stored to absorb
    # a schema change, would not be reflected when reading old ciphertext.
    stored = decode(record.encrypted_profile)
    assert stored == record.profile
  end
end
