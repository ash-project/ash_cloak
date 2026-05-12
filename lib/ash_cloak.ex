# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak do
  @moduledoc """
  An extension for encrypting attributes of a resource.

  See the getting started guide for more information.
  """

  @transformers [
    AshCloak.Transformers.SetupEncryption
  ]

  @cloak %Spark.Dsl.Section{
    name: :cloak,
    describe: "Encrypt attributes of a resource",
    schema: [
      vault: [
        type: {:or, [{:behaviour, Cloak.Vault}, {:fun, 2}, :mfa]},
        doc:
          "The vault to use to encrypt & decrypt the value. Accepts a module implementing `Cloak.Vault`, a `fun/2` of the form `(resource_module, context) -> vault_module`, or an MFA tuple. When a function or MFA is given, it is called at every encrypt and decrypt operation and its return value is used as the vault module.",
        required: true
      ],
      attributes: [
        type: {:wrap_list, :atom},
        default: [],
        doc:
          "The attribute or attributes to encrypt. The attribute will be renamed to `encrypted_{attribute}`, and a calculation with the same name will be added."
      ],
      decrypt_by_default: [
        type: {:wrap_list, :atom},
        default: [],
        doc:
          "A list of attributes that should be decrypted (their calculation should be loaded) by default."
      ],
      on_decrypt: [
        type: {:or, [{:fun, 4}, :mfa]},
        doc:
          "A function to call when decrypting any value. Takes the resource, field, records, and calculation context. Must return `:ok` or `{:error, error}`"
      ]
    ]
  }

  use Spark.Dsl.Extension, sections: [@cloak], transformers: @transformers

  @doc """
  Encrypts and writes to an encrypted attribute.

  If the changeset is pending (i.e not currently running the action), then it is added as a before_action hook.
  Otherwise, it is run immediately

  Raises AshCloak.Errors.NoSuchEncryptedAttribute if the attribute is not configured for encryption.
  """
  @spec encrypt_and_set(Ash.Changeset.t(), attr :: atom, term :: term) :: Ash.Changeset.t()
  def encrypt_and_set(changeset, key, value, context \\ nil) do
    if key in AshCloak.Info.cloak_attributes!(changeset.resource) do
      if changeset.phase == :pending do
        Ash.Changeset.before_action(changeset, &do_encrypt_and_set(&1, key, value, context))
      else
        do_encrypt_and_set(changeset, key, value, context)
      end
    else
      raise AshCloak.Errors.NoSuchEncryptedAttribute, key: key, resource: changeset.resource
    end
  end

  @doc false
  def resolve_vault(resource, context) do
    case AshCloak.Info.cloak_vault!(resource) do
      {m, f, a} ->
        apply(m, f, [resource, context | List.wrap(a)])

      fun when is_function(fun, 2) ->
        fun.(resource, context)

      vault ->
        vault
    end
  end

  @doc false
  def do_encrypt(resource, value, context \\ nil) do
    vault = resolve_vault(resource, context)

    value
    |> :erlang.term_to_binary()
    |> vault.encrypt!()
    |> Base.encode64()
  end

  defp do_encrypt_and_set(changeset, key, value, context) do
    encrypted_value = do_encrypt(changeset.resource, value, context)
    encryption_target = String.to_existing_atom("encrypted_#{key}")

    changeset
    |> Ash.Changeset.force_change_attribute(encryption_target, encrypted_value)
    |> Map.update!(:arguments, &Map.delete(&1, key))
    |> Map.update!(:params, fn params ->
      Map.drop(params, [key, to_string(key)])
    end)
  end
end
