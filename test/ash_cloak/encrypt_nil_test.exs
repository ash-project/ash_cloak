# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.EncryptNilTest do
  use ExUnit.Case

  require Ash.Query

  defp decode(value) do
    "encrypted " <> value = Base.decode64!(value)
    Ash.Helpers.non_executable_binary_to_term(value)
  end

  describe "encrypt_nil? introspection" do
    test "defaults to true, preserving the original behavior" do
      assert AshCloak.Info.cloak_encrypt_nil?(AshCloak.Test.Resource) == true
    end

    test "is false when configured" do
      assert AshCloak.Info.cloak_encrypt_nil?(AshCloak.Test.NilResource) == false
    end
  end

  describe "encrypt_nil? true (default)" do
    test "encrypts nil into a non-null ciphertext" do
      created =
        AshCloak.Test.Resource
        |> Ash.Changeset.for_create(:create, %{encrypted: nil})
        |> Ash.create!()

      # a nil value is still encrypted, so the backing column is NOT NULL ...
      assert created.encrypted_encrypted != nil
      # ... and decrypts back to nil
      assert decode(created.encrypted_encrypted) == nil
    end

    test "do_encrypt/4 encrypts a nil value" do
      assert AshCloak.do_encrypt(AshCloak.Test.Resource, :encrypted, nil) != nil
    end
  end

  describe "encrypt_nil? false" do
    test "stores nil as SQL NULL on create and round-trips back to nil" do
      created =
        AshCloak.Test.NilResource
        |> Ash.Changeset.for_create(:create, %{encrypted: nil})
        |> Ash.create!()

      # the backing column is SQL NULL, so `IS NOT NULL` stays meaningful
      assert created.encrypted_encrypted == nil

      # and the decrypt calculation maps the NULL back to nil
      loaded = Ash.load!(created, [:encrypted])
      assert loaded.encrypted == nil
    end

    test "still encrypts a non-nil value" do
      created =
        AshCloak.Test.NilResource
        |> Ash.Changeset.for_create(:create, %{encrypted: 12})
        |> Ash.create!()

      assert decode(created.encrypted_encrypted) == 12
      assert Ash.load!(created, [:encrypted]).encrypted == 12
    end

    test "clears the backing column to NULL on update" do
      created =
        AshCloak.Test.NilResource
        |> Ash.Changeset.for_create(:create, %{encrypted: 12})
        |> Ash.create!()

      assert created.encrypted_encrypted != nil

      updated =
        created
        |> Ash.Changeset.for_update(:update, %{encrypted: nil})
        |> Ash.update!()

      assert updated.encrypted_encrypted == nil
      assert Ash.load!(updated, [:encrypted]).encrypted == nil
    end

    test "clears the backing column to NULL on atomic/bulk update" do
      created =
        AshCloak.Test.NilResource
        |> Ash.Changeset.for_create(:create, %{encrypted: 12})
        |> Ash.create!()

      assert %Ash.BulkResult{records: [updated]} =
               AshCloak.Test.NilResource
               |> Ash.Query.filter(id == ^created.id)
               |> Ash.bulk_update!(:update, %{encrypted: nil}, return_records?: true)

      assert updated.encrypted_encrypted == nil
      assert Ash.load!(updated, [:encrypted]).encrypted == nil
    end

    test "do_encrypt/4 returns nil for a nil value but encrypts other values" do
      assert AshCloak.do_encrypt(AshCloak.Test.NilResource, :encrypted, nil) == nil
      assert AshCloak.do_encrypt(AshCloak.Test.NilResource, :encrypted, 5) != nil
    end
  end
end
