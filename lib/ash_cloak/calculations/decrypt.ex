defmodule AshCloak.Calculations.Decrypt do
  @moduledoc false
  use Ash.Resource.Calculation

  def load(_, opts, _), do: [opts[:field]]

  def calculate([%resource{} | _] = records, opts, context) do
    vault = AshCloak.Info.cloak_vault!(resource)
    plain_field = opts[:plain_field]

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
              |> Base.decode64!()
              |> vault.decrypt!()
              |> Ash.Helpers.non_executable_binary_to_term()
          end
        end)

      {:error, error} ->
        {:error, error}
    end
  end

  def calculate([], _, _), do: []

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
