# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.SafeDecodeTest do
  use ExUnit.Case

  alias AshCloak.Test.{EmbeddedProfile, ResourceWithEmbedded, UnsafeDecodeResource}

  # A name for an atom that does not exist in the VM. Tests only ever build its ETF
  # encoding by hand, so the atom is interned only if decoding interns it.
  defp unknown_atom_name, do: "ash_cloak_unknown_atom_#{System.unique_integer([:positive])}"

  defp atom_ext(name), do: <<119, byte_size(name)::8, name::binary>>

  # Mirrors the AshCloak.Test.Vault format: "encrypted " <> term_to_binary, base64-encoded.
  defp stored(term_binary), do: Base.encode64("encrypted " <> term_binary)

  # The embedded representation of a profile whose stored map also carries a key for an
  # atom not yet in the VM, as happens when the embedded module is not loaded yet.
  defp embedded_payload_with_unknown_key(name) do
    placeholder = :ash_cloak_placeholder_key

    {:__ash_cloak__, %{nickname: "neo", age: 30, ash_cloak_placeholder_key: "x"}}
    |> :erlang.term_to_binary()
    |> :binary.replace(atom_ext(Atom.to_string(placeholder)), atom_ext(name))
  end

  describe "safe_decode? introspection" do
    test "defaults to true" do
      assert AshCloak.Info.cloak_safe_decode?(AshCloak.Test.Resource) == true
    end

    test "is false when configured" do
      assert AshCloak.Info.cloak_safe_decode?(UnsafeDecodeResource) == false
    end
  end

  describe "safe_decode? false" do
    test "decrypts a payload containing an atom not yet in the VM" do
      name = unknown_atom_name()

      record =
        Ash.Seed.seed!(UnsafeDecodeResource, %{
          encrypted_data: stored(<<131>> <> atom_ext(name))
        })

      loaded = Ash.load!(record, :data)

      assert loaded.data == String.to_existing_atom(name)
    end

    test "restores an embedded value whose stored keys are not yet atoms in the VM" do
      name = unknown_atom_name()

      record =
        Ash.Seed.seed!(UnsafeDecodeResource, %{
          encrypted_profile: stored(embedded_payload_with_unknown_key(name))
        })

      loaded = Ash.load!(record, :profile)

      assert %EmbeddedProfile{nickname: "neo", age: 30} = loaded.profile
    end

    test "round-trips an embedded value" do
      record =
        UnsafeDecodeResource
        |> Ash.Changeset.for_create(:create, %{profile: %{nickname: "neo", age: 30}})
        |> Ash.create!()

      assert %EmbeddedProfile{nickname: "neo", age: 30} =
               Ash.load!(record, :profile).profile
    end

    test "still refuses a compressed term" do
      compressed = :erlang.term_to_binary(List.duplicate("aaaaaaaa", 2000), [:compressed])

      record = Ash.Seed.seed!(UnsafeDecodeResource, %{encrypted_data: stored(compressed)})

      error = assert_raise Ash.Error.Unknown, fn -> Ash.load!(record, :data) end

      assert Exception.message(error) =~ "compressed"
    end

    test "still refuses executable terms" do
      fun_term = :erlang.term_to_binary(fn -> :ok end)

      record = Ash.Seed.seed!(UnsafeDecodeResource, %{encrypted_data: stored(fun_term)})

      assert_raise Ash.Error.Unknown, fn -> Ash.load!(record, :data) end
    end
  end

  describe "safe_decode? true (default)" do
    test "rejects an embedded payload whose stored keys are not yet atoms in the VM" do
      name = unknown_atom_name()

      record =
        Ash.Seed.seed!(ResourceWithEmbedded, %{
          encrypted_profile: stored(embedded_payload_with_unknown_key(name))
        })

      error = assert_raise Ash.Error.Unknown, fn -> Ash.load!(record, :profile) end

      assert Exception.message(error) =~ "unsafe"
      assert_raise ArgumentError, fn -> String.to_existing_atom(name) end
    end
  end
end
