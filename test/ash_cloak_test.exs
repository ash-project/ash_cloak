defmodule AshCloakTest do
  use ExUnit.Case
  doctest AshCloak

  defp decode(value) do
    "encrypted " <> value = Base.decode64!(value)
    :erlang.binary_to_term(value)
  end

  test "it encrypts the input values" do
    encrypted =
      AshCloak.Test.Resource
      |> Ash.Changeset.for_create(:create, %{
        not_encrypted: "plain",
        encrypted: 12,
        encrypted_always_loaded: %{hello: :world}
      })
      |> Ash.Changeset.set_context(%{foo: :bar})
      |> Ash.create!()

    # encrypted value is stored
    assert decode(encrypted.encrypted_encrypted) == 12

    # complex values are encrypted
    assert decode(encrypted.encrypted_encrypted_always_loaded) == %{hello: :world}

    # values are not loaded unless you request them
    assert %Ash.NotLoaded{} = encrypted.encrypted

    # values that are requested are loaded by default
    assert encrypted.encrypted_always_loaded == %{hello: :world}

    # plain attribtues are not affected
    assert encrypted.not_encrypted == "plain"

    # on_decrypt is notified
    assert_received {:decrypting, AshCloak.Test.Resource, [_], :encrypted_always_loaded, %{}}

    # only for fields that are being decrypted
    refute_received {:decrypting, _, _, _, _}
  end
end
