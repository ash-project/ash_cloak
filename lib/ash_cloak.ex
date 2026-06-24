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
  def do_encrypt(resource, field, value, context \\ nil) do
    vault = resolve_vault(resource, context)

    encrypted =
      resource
      |> serialize(field, value)
      |> vault.encrypt!()

    if embedded_binary_handles_encoding?(resource) do
      encrypted
    else
      Base.encode64(encrypted)
    end
  end

  # Serialize a value for encryption.
  #
  # For types whose serializable representation differs from their in-memory value —
  # embedded resources, unions, and arrays of them — we encrypt that representation
  # (`Ash.Type.dump_to_embedded/3`, which is built to produce a plain serializable
  # structure and so never contains structs) tagged with `:__ash_cloak__`, so reads can
  # restore it via `Ash.Type.cast_from_embedded/3`. That gives encrypted embedded/union
  # attributes the same schema-evolution semantics as unencrypted ones, instead of
  # serializing the raw struct (module tag and internal fields included).
  #
  # For every other type the serializable representation is identical to the value, so
  # we keep the original untagged `term_to_binary/1` format and stay byte-compatible
  # with data written by earlier versions.
  #
  # The `:__ash_cloak__` sentinel distinguishes new payloads from legacy ones on read.
  # A legacy value is only mistaken for one if it is literally `{:__ash_cloak__, _}` —
  # effectively impossible, since that atom is internal to this library and `:term`
  # types (the only ones that could hold such a tuple) dump to themselves and are never
  # tagged here.
  defp serialize(resource, field, value) do
    %{type: type, constraints: constraints} = Ash.Resource.Info.calculation(resource, field)

    case Ash.Type.dump_to_embedded(type, value, constraints) do
      {:ok, dumped} when dumped !== value ->
        :erlang.term_to_binary({:__ash_cloak__, dumped})

      {:ok, _dumped} ->
        :erlang.term_to_binary(value)

      other ->
        raise ArgumentError,
              "AshCloak could not dump #{inspect(field)} on #{inspect(resource)} to its " <>
                "embedded representation for encryption: #{inspect(other)}"
    end
  end

  @doc false
  def embedded_binary_handles_encoding?(resource) do
    Ash.Resource.Info.embedded?(resource) and
      Code.ensure_loaded?(Ash.Type.Binary) and
      function_exported?(Ash.Type.Binary, :cast_from_embedded, 2)
  end

  defp do_encrypt_and_set(changeset, key, value, context) do
    encrypted_value = do_encrypt(changeset.resource, key, value, context)
    encryption_target = String.to_existing_atom("encrypted_#{key}")

    changeset
    |> Ash.Changeset.force_change_attribute(encryption_target, encrypted_value)
    |> Map.update!(:arguments, &Map.delete(&1, key))
    |> Map.update!(:params, fn params ->
      Map.drop(params, [key, to_string(key)])
    end)
  end
end
