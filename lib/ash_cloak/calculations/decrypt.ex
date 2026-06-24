# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Calculations.Decrypt do
  @moduledoc false
  use Ash.Resource.Calculation

  def load(_, opts, _), do: [opts[:field]]

  def calculate([%resource{} | _] = records, opts, context) do
    vault = AshCloak.resolve_vault(resource, context)
    plain_field = opts[:plain_field]
    skip_base64? = AshCloak.embedded_binary_handles_encoding?(resource)
    %{type: type, constraints: constraints} = Ash.Resource.Info.calculation(resource, plain_field)

    case approve_decrypt(resource, records, plain_field, context) do
      :ok ->
        Enum.map(records, fn record ->
          record
          |> Map.get(opts[:field])
          |> case do
            nil ->
              nil

            value ->
              value
              |> maybe_decode64(skip_base64?)
              |> vault.decrypt!()
              |> Ash.Helpers.non_executable_binary_to_term()
              |> deserialize(type, constraints)
          end
        end)

      {:error, error} ->
        {:error, error}
    end
  end

  def calculate([], _, _), do: []

  # Values written after the serialization change are tagged and restored via
  # `Ash.Type.cast_from_embedded/3`. Values written before it — and scalar values, which
  # were never tagged — are the raw term and are returned as-is, keeping existing
  # encrypted data readable.
  defp deserialize({:__ash_cloak__, dumped}, type, constraints) do
    case Ash.Type.cast_from_embedded(type, dumped, constraints) do
      {:ok, value} ->
        value

      other ->
        raise ArgumentError,
              "AshCloak could not load the stored value for #{inspect(type)} via " <>
                "cast_from_embedded/3: #{inspect(other)}"
    end
  end

  defp deserialize(legacy_value, _type, _constraints), do: legacy_value

  defp maybe_decode64(value, true), do: value
  defp maybe_decode64(value, false), do: Base.decode64!(value)

  defp approve_decrypt(resource, records, field, context) do
    case AshCloak.Info.cloak_on_decrypt(resource) do
      {:ok, {m, f, a}} ->
        apply(m, f, [resource, records, field, context] ++ List.wrap(a))

      {:ok, function} when is_function(function, 4) ->
        function.(resource, records, field, context)

      :error ->
        :ok
    end
  end
end
