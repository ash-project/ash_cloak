# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Transformers.SetupEncryption do
  @moduledoc false
  use Spark.Dsl.Transformer

  # sobelow_skip ["DOS.BinToAtom", "DOS.StringToAtom"]
  def transform(dsl) do
    module = Spark.Dsl.Transformer.get_persisted(dsl, :module)
    cloaked_attrs = AshCloak.Info.cloak_attributes!(dsl)

    Enum.reduce_while(cloaked_attrs, {:ok, dsl}, fn attr, {:ok, dsl} ->
      attribute = Ash.Resource.Info.attribute(dsl, attr)

      if !attribute do
        raise Spark.Error.DslError,
          module: module,
          message: "No attribute called #{inspect(attr)} found",
          path: [:cloak, :attributes]
      end

      if attribute.primary_key? do
        raise Spark.Error.DslError,
          module: module,
          message: "cannot encrypt primary key attribute",
          path: [:cloak, :attributes]
      end

      name = attribute.name

      dsl
      |> Spark.Dsl.Transformer.remove_entity([:attributes], &(&1.name == attribute.name))
      |> Ash.Resource.Builder.add_attribute(:"encrypted_#{name}", :binary,
        allow_nil?: attribute.allow_nil?,
        sensitive?: true,
        public?: false,
        description: "Encrypted #{attribute.name}"
      )
      |> Ash.Resource.Builder.add_calculation(
        attribute.name,
        attribute.type,
        {AshCloak.Calculations.Decrypt, [field: :"encrypted_#{name}", plain_field: name]},
        [
          public?: attribute.public?,
          constraints: attribute.constraints,
          allow_nil?: attribute.allow_nil?,
          sensitive?: true,
          filterable?: false,
          sortable?: false
        ]
        |> add_description(attribute)
      )
      |> rewrite_actions(attribute)
      |> case do
        {:ok, dsl} -> {:cont, {:ok, dsl}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> add_automatic_decrypt_preparation_and_change()
  end

  defp add_description(opts, %{description: description}) when is_binary(description) do
    Keyword.put(opts, :description, description)
  end

  defp add_description(opts, _), do: opts

  defp add_automatic_decrypt_preparation_and_change({:ok, dsl}) do
    case AshCloak.Info.cloak_decrypt_by_default!(dsl) do
      [] ->
        {:ok, dsl}

      decrypt_by_default ->
        dsl
        |> Ash.Resource.Builder.add_change({Ash.Resource.Change.Load, target: decrypt_by_default})
        |> Ash.Resource.Builder.add_preparation(
          {Ash.Resource.Preparation.Build, options: [load: decrypt_by_default]}
        )
    end
  end

  defp add_automatic_decrypt_preparation_and_change({:error, error}) do
    {:error, error}
  end

  defp rewrite_actions({:ok, dsl}, attr) do
    dsl
    |> Ash.Resource.Info.actions()
    |> Enum.filter(&(&1.type in [:create, :update, :destroy] && attr.name in &1.accept))
    |> Enum.reduce_while({:ok, dsl}, fn action, {:ok, dsl} ->
      new_accept = action.accept -- [attr.name]

      opts =
        case action.type do
          :create -> [constraints: attr.constraints, default: attr.default]
          _ -> [constraints: attr.constraints]
        end

      with {:ok, argument} <-
             Ash.Resource.Builder.build_action_argument(attr.name, attr.type, opts),
           {:ok, change} <-
             Ash.Resource.Builder.build_action_change(
               {AshCloak.Changes.Encrypt, field: attr.name}
             ) do
        {:cont,
         {:ok,
          Spark.Dsl.Transformer.replace_entity(
            dsl,
            [:actions],
            %{
              action
              | arguments: [argument | Enum.reject(action.arguments, &(&1.name == attr.name))],
                changes: [change | action.changes],
                accept: new_accept
            },
            &(&1.name == action.name)
          )}}
      else
        other ->
          {:halt, other}
      end
    end)
  end

  defp rewrite_actions({:error, error}, _), do: {:error, error}

  def after?(Ash.Resource.Transformers.DefaultAccept), do: true
  def after?(_), do: false
end
