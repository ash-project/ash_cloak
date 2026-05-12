# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.VaultSelectorTest do
  use ExUnit.Case, async: true

  require Ash.Query

  # Returns :default or :alt based on which vault's ciphertext prefix is present
  defp raw_vault_prefix(record, field) do
    raw = Map.get(record, :"encrypted_#{field}")
    decoded = Base.decode64!(raw)

    cond do
      String.starts_with?(decoded, "alt_encrypted ") -> :alt
      String.starts_with?(decoded, "encrypted ") -> :default
    end
  end

  describe "vault_selector (MFA form)" do
    test "uses static vault when source_context has no test_vault key" do
      record =
        AshCloak.Test.ResourceWithSelector
        |> Ash.Changeset.for_create(:create, %{encrypted: 42})
        |> Ash.create!()

      assert raw_vault_prefix(record, :encrypted) == :default
    end

    test "uses alt vault when source_context has test_vault: :alt" do
      record =
        AshCloak.Test.ResourceWithSelector
        |> Ash.Changeset.for_create(:create, %{encrypted: 42})
        |> Ash.Changeset.set_context(%{test_vault: :alt})
        |> Ash.create!()

      assert raw_vault_prefix(record, :encrypted) == :alt
    end

    test "update action uses vault selector" do
      record =
        AshCloak.Test.ResourceWithSelector
        |> Ash.Changeset.for_create(:create, %{encrypted: 1})
        |> Ash.create!()

      updated =
        record
        |> Ash.Changeset.for_update(:update, %{encrypted: 2})
        |> Ash.Changeset.set_context(%{test_vault: :alt})
        |> Ash.update!()

      assert raw_vault_prefix(updated, :encrypted) == :alt
    end

    test "atomic bulk update uses vault selector" do
      record =
        AshCloak.Test.ResourceWithSelector
        |> Ash.Changeset.for_create(:create, %{encrypted: 1})
        |> Ash.create!()

      %Ash.BulkResult{records: [updated]} =
        AshCloak.Test.ResourceWithSelector
        |> Ash.Query.filter(id == ^record.id)
        |> Ash.bulk_update!(
          :update,
          %{encrypted: 2},
          return_records?: true,
          context: %{test_vault: :alt}
        )

      assert raw_vault_prefix(updated, :encrypted) == :alt
    end

    test "decrypt uses vault selector to choose correct vault" do
      record =
        AshCloak.Test.ResourceWithSelector
        |> Ash.Changeset.for_create(:create, %{encrypted: 99})
        |> Ash.Changeset.set_context(%{test_vault: :alt})
        |> Ash.create!()

      assert raw_vault_prefix(record, :encrypted) == :alt

      loaded = Ash.load!(record, [:encrypted], context: %{test_vault: :alt})
      assert loaded.encrypted == 99
    end

    test "different contexts produce ciphertext decryptable only by their respective vault" do
      default_record =
        AshCloak.Test.ResourceWithSelector
        |> Ash.Changeset.for_create(:create, %{encrypted: 10})
        |> Ash.create!()

      alt_record =
        AshCloak.Test.ResourceWithSelector
        |> Ash.Changeset.for_create(:create, %{encrypted: 20})
        |> Ash.Changeset.set_context(%{test_vault: :alt})
        |> Ash.create!()

      assert raw_vault_prefix(default_record, :encrypted) == :default
      assert raw_vault_prefix(alt_record, :encrypted) == :alt

      assert Ash.load!(default_record, [:encrypted]).encrypted == 10
      assert Ash.load!(alt_record, [:encrypted], context: %{test_vault: :alt}).encrypted == 20
    end

    test "MFA dispatch: apply(m, f, [resource, context] ++ a) is invoked" do
      # ResourceWithSelector uses {AshCloak.Test.VaultSelector, :select, []}
      # Verify the MFA path executes correctly by confirming alt vault is selected
      # when source_context carries the expected key
      record =
        AshCloak.Test.ResourceWithSelector
        |> Ash.Changeset.for_create(:create, %{encrypted: 55})
        |> Ash.Changeset.set_context(%{test_vault: :alt})
        |> Ash.create!()

      assert raw_vault_prefix(record, :encrypted) == :alt
    end

    test "MFA dispatch falls back to static vault without matching source_context" do
      record =
        AshCloak.Test.ResourceWithSelector
        |> Ash.Changeset.for_create(:create, %{encrypted: 55})
        |> Ash.create!()

      assert raw_vault_prefix(record, :encrypted) == :default
    end
  end

  describe "encrypt_and_set with vault_selector" do
    test "encrypt_and_set without Ash action context falls back to static vault" do
      record =
        AshCloak.Test.ResourceWithSelector
        |> Ash.Changeset.for_create(:create, %{})
        |> AshCloak.encrypt_and_set(:encrypted, 77)
        |> Ash.create!()

      assert raw_vault_prefix(record, :encrypted) == :default
    end
  end
end
