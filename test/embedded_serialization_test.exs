# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.EmbeddedSerializationTest do
  @moduledoc """
  An encrypted attribute whose type is an embedded resource (or a union of embedded
  resources) is serialized through the type's embedded representation
  (`Ash.Type.dump_to_embedded/3`) and restored via `Ash.Type.cast_from_embedded/3`, so
  it gets the same schema-evolution semantics as an unencrypted embedded attribute.

  Data written before this change (the raw struct, `term_to_binary`'d with no tag)
  must keep decrypting.
  """
  use ExUnit.Case

  alias AshCloak.Test.{EmbeddedProfile, ResourceWithEmbedded, ResourceWithUnion}

  # Mirrors the AshCloak.Test.Vault format: "encrypted " <> term_to_binary, base64-encoded.
  defp decode(value) do
    "encrypted " <> binary = Base.decode64!(value)
    Ash.Helpers.non_executable_binary_to_term(binary)
  end

  defp embedded_representation(resource, field, value) do
    %{type: type, constraints: constraints} = Ash.Resource.Info.calculation(resource, field)
    {:ok, dumped} = Ash.Type.dump_to_embedded(type, value, constraints)
    dumped
  end

  test "an embedded attribute stores its storage representation, not the raw struct" do
    record =
      ResourceWithEmbedded
      |> Ash.Changeset.for_create(:create, %{profile: %{nickname: "neo", age: 30}})
      |> Ash.create!()

    assert {:__ash_cloak__, dumped} = decode(record.encrypted_profile)

    # The stored payload is the struct-free embedded representation: no __struct__ tag,
    # and no internal fields that dump_to_embedded/3 strips.
    refute is_struct(dumped)
    assert is_map(dumped)
    refute Map.has_key?(dumped, :__meta__)
    assert dumped == embedded_representation(ResourceWithEmbedded, :profile, record.profile)

    # It round-trips back through cast_from_embedded/3 into a clean struct.
    assert %EmbeddedProfile{nickname: "neo", age: 30} = record.profile
  end

  test "a union-of-embedded attribute stores its storage representation" do
    record =
      ResourceWithUnion
      |> Ash.Changeset.for_create(:create, %{thing: %{nickname: "trinity", age: 28}})
      |> Ash.create!()

    assert {:__ash_cloak__, dumped} = decode(record.encrypted_thing)

    refute is_struct(dumped)
    assert dumped == embedded_representation(ResourceWithUnion, :thing, record.thing)

    assert %Ash.Union{type: :profile, value: %EmbeddedProfile{nickname: "trinity", age: 28}} =
             record.thing
  end

  test "decrypts pre-change data written in the old raw-term format" do
    # A row written before the storage-representation change: the raw cast struct,
    # term_to_binary'd, encrypted, base64-encoded — with no :__ash_cloak__ tag.
    old_blob =
      %EmbeddedProfile{nickname: "neo", age: 30}
      |> :erlang.term_to_binary()
      |> AshCloak.Test.Vault.encrypt!()
      |> Base.encode64()

    record = %ResourceWithEmbedded{id: Ash.UUID.generate(), encrypted_profile: old_blob}

    loaded = Ash.load!(record, [:profile], domain: AshCloak.Test.Domain)

    assert %EmbeddedProfile{nickname: "neo", age: 30} = loaded.profile
  end
end
