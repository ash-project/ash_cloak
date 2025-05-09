defmodule AshCloakTest do
  use ExUnit.Case
  doctest AshCloak

  require Ash.Query

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

  test "it encrypts input values on update" do
    encrypted =
      AshCloak.Test.Resource
      |> Ash.Changeset.for_create(:create, %{
        not_encrypted: "plain",
        encrypted: 12,
        encrypted_always_loaded: %{hello: :world}
      })
      |> Ash.Changeset.set_context(%{foo: :bar})
      |> Ash.create!()
      |> Ash.Changeset.for_update(:update, %{
        not_encrypted: "plain2",
        encrypted: 13,
        encrypted_always_loaded: %{hello: :world2}
      })
      |> Ash.update!()

    assert_received {:decrypting, AshCloak.Test.Resource, [_], :encrypted_always_loaded, %{}}

    # encrypted value is stored
    assert decode(encrypted.encrypted_encrypted) == 13

    # complex values are encrypted
    assert decode(encrypted.encrypted_encrypted_always_loaded) == %{hello: :world2}

    # values are not loaded unless you request them
    assert %Ash.NotLoaded{} = encrypted.encrypted

    # values that are requested are loaded by default
    assert encrypted.encrypted_always_loaded == %{hello: :world2}

    # plain attribtues are not affected
    assert encrypted.not_encrypted == "plain2"

    # on_decrypt is notified
    assert_received {:decrypting, AshCloak.Test.Resource, [_], :encrypted_always_loaded, %{}}

    # only for fields that are being decrypted
    refute_received {:decrypting, _, _, _, _}
  end

  test "it encrypts input values on atomic update" do
    encrypted =
      AshCloak.Test.Resource
      |> Ash.Changeset.for_create(:create, %{
        not_encrypted: "plain",
        encrypted: 12,
        encrypted_always_loaded: %{hello: :world}
      })
      |> Ash.Changeset.set_context(%{foo: :bar})
      |> Ash.create!()

    assert_received {:decrypting, AshCloak.Test.Resource, [_], :encrypted_always_loaded, %{}}

    assert %Ash.BulkResult{records: [encrypted]} =
             AshCloak.Test.Resource
             |> Ash.Query.filter(id == ^encrypted.id)
             |> Ash.bulk_update!(
               :update,
               %{
                 not_encrypted: "plain2",
                 encrypted: 13,
                 encrypted_always_loaded: %{hello: :world2}
               },
               return_records?: true
             )

    assert_received {:decrypting, AshCloak.Test.Resource, [_], :encrypted_always_loaded, %{}}

    # encrypted value is stored
    assert decode(encrypted.encrypted_encrypted) == 13

    # complex values are encrypted
    assert decode(encrypted.encrypted_encrypted_always_loaded) == %{hello: :world2}

    # values are not loaded unless you request them
    assert %Ash.NotLoaded{} = encrypted.encrypted

    # values that are requested are loaded by default
    assert encrypted.encrypted_always_loaded == %{hello: :world2}

    # plain attribtues are not affected
    assert encrypted.not_encrypted == "plain2"

    # only for fields that are being decrypted
    refute_received {:decrypting, _, _, _, _}
  end

  test "encrypt after action change" do
    encrypted =
      AshCloak.Test.Resource
      |> Ash.Changeset.for_create(:change_before_encrypt, %{
        not_encrypted: "plain",
        encrypted_always_loaded: %{hello: :world}
      })
      |> Ash.Changeset.set_context(%{foo: :bar})
      |> Ash.create!()

    assert decode(encrypted.encrypted_encrypted) == 13
  end

  test "it encrypt by set_argument directly" do
    encrypted =
      AshCloak.Test.Resource
      |> Ash.Changeset.new()
      |> Ash.Changeset.set_argument(:encrypted, 14)
      |> Ash.Changeset.for_create(:create, %{
        not_encrypted: "plain",
        encrypted_always_loaded: %{hello: :world}
      })
      |> Ash.Changeset.set_context(%{foo: :bar})
      |> Ash.create!()

    assert decode(encrypted.encrypted_encrypted) == 14
  end

  test "it encrypts even when the attribute is not in the accept list" do
    encrypted =
      AshCloak.Test.Resource
      |> Ash.Changeset.for_create(:change_without_accept)
      |> Ash.create!()

    assert decode(encrypted.encrypted_encrypted) == 13
  end

  test "it encrypts with default value" do
    encrypted =
      AshCloak.Test.Resource
      |> Ash.Changeset.for_create(:create, %{})
      |> Ash.create!()

    assert decode(encrypted.encrypted_encrypted_with_default) == 42
  end

  test "it doesn't update not accepted encrypted fields with default value" do
    encrypted =
      AshCloak.Test.Resource
      |> Ash.Changeset.for_create(:create, %{encrypted_with_default: 1})
      |> Ash.create!()

    assert decode(encrypted.encrypted_encrypted_with_default) == 1

    updated_encrypted =
      encrypted
      |> Ash.Changeset.for_update(:update_not_encrypted, %{not_encrypted: "plain"})
      |> Ash.update!()

    assert updated_encrypted.not_encrypted == "plain"
    assert decode(updated_encrypted.encrypted_encrypted_with_default) == 1
  end

  test "encrypt_and_set encrypts and sets values correctly" do
    # Test with pending changeset
    pending_changeset =
      AshCloak.Test.Resource
      |> Ash.Changeset.for_create(:create, %{not_encrypted: "plain"})
      |> AshCloak.encrypt_and_set(:encrypted, 15)
      |> Ash.create!()

    assert decode(pending_changeset.encrypted_encrypted) == 15

    # Test with non-pending changeset (during action)
    changeset =
      AshCloak.Test.Resource
      |> Ash.Changeset.for_create(:create, %{not_encrypted: "plain"})
      |> Map.put(:phase, :action)
      |> AshCloak.encrypt_and_set(:encrypted, 16)
      |> Ash.create!()

    assert decode(changeset.encrypted_encrypted) == 16

    # Test with invalid attribute
    assert_raise AshCloak.Errors.NoSuchEncryptedAttribute, fn ->
      AshCloak.Test.Resource
      |> Ash.Changeset.for_create(:create, %{})
      |> AshCloak.encrypt_and_set(:non_existent, "value")
    end
  end
end
