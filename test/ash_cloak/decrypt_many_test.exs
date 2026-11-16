# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.DecryptManyTest do
  use ExUnit.Case, async: true

  alias AshCloak.Test.BatchResource

  defp create!(position, value) do
    BatchResource
    |> Ash.Changeset.for_create(:create, %{position: position, encrypted: value})
    |> Ash.create!()
  end

  defp ciphertext(record), do: Base.decode64!(record.encrypted_encrypted)

  describe "a vault that exports decrypt_many!/1" do
    test "decrypts the records of a load in one call, in order" do
      records = for position <- 1..3, do: create!(position, position * 10)

      loaded = Ash.load!(records, [:encrypted])

      assert Enum.map(loaded, & &1.encrypted) == [10, 20, 30]

      expected = Enum.map(records, &ciphertext/1)
      assert_received {:decrypt_many, ^expected}
      refute_received {:decrypt_many, _}
      refute_received {:decrypt, _}
    end

    test "leaves a nil value out of the batch and answers nil for it" do
      first = create!(1, 10)
      empty = create!(2, nil)
      last = create!(3, 30)

      loaded = Ash.load!([first, empty, last], [:encrypted])

      assert Enum.map(loaded, & &1.encrypted) == [10, nil, 30]

      expected = [ciphertext(first), ciphertext(last)]
      assert_received {:decrypt_many, ^expected}
      refute_received {:decrypt_many, _}
    end

    test "is not called when no record has a value to decrypt" do
      loaded = Ash.load!([create!(1, nil), create!(2, nil)], [:encrypted])

      assert Enum.map(loaded, & &1.encrypted) == [nil, nil]
      refute_received {:decrypt_many, _}
    end
  end

  describe "a vault without decrypt_many!/1" do
    test "is still called once per value" do
      records =
        for value <- [1, 2] do
          AshCloak.Test.NilResource
          |> Ash.Changeset.for_create(:create, %{encrypted: value})
          |> Ash.create!()
        end

      assert [1, 2] = records |> Ash.load!([:encrypted]) |> Enum.map(& &1.encrypted)
    end
  end
end
