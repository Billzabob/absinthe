defmodule Absinthe.Introspection.Types do

  @moduledoc false

  use Absinthe.Type.Definitions
  alias Absinthe.Flag
  alias Absinthe.Type

  @absinthe :type
  def __type do
    %Type.Object{
      name: "__Type",
      description: "Represents scalars, interfaces, object types, unions, enums in the system",
      fields: fields(
        kind: [
          type: :string,
          resolve: fn
            _, %{resolution: %{target: %{__struct__: type}}} ->
              {:ok, type.kind}
          end
        ],
        name: [type: :string],
        description: [type: :string],
        fields: [
          type: list_of(:__field),
          args: args(
            include_deprecated: [
              type: :boolean,
              default_value: false
            ]
          ),
          resolve: fn
            %{include_deprecated: show_deprecated}, %{resolution: %{target: %{fields: fields}}} ->
              fields
              |> Enum.flat_map(fn
                {_, %{deprecation: is_deprecated} = field} ->
                  if !is_deprecated || (is_deprecated && show_deprecated) do
                    [field]
                  else
                    []
                  end
              end)
              |> Flag.as(:ok)
            _, _ ->
              {:ok, nil}
          end
        ],
        interfaces: [
          type: list_of(:__type),
          resolve: fn
            _, %{schema: schema, resolution: %{target: %{interfaces: interfaces}}} ->
              structs = interfaces
              |> Enum.map(fn
                ident -> schema.types[ident]
              end)
              {:ok, structs}
            _, _ ->
              {:ok, nil}
          end
        ],
        possible_types: [
          type: list_of(:__type),
          resolve: fn
            _, %{schema: schema, resolution: %{target: %Type.Union{types: types}}} ->
              structs = types |> Enum.map(fn name -> schema.types[name] end)
              {:ok, structs}
            _, %{schema: schema, resolution: %{target: %Type.Interface{reference: %{identifier: ident}}}} ->
              implementors = schema.interfaces[ident]
              structs = implementors |> Enum.map(fn name -> schema.types[name] end)
              {:ok, structs}
            _, _ ->
              {:ok, nil}
          end
        ],
        enum_values: [
          type: list_of(:__enumvalue),
          args: args(
            include_deprecated: [
              type: :boolean,
              default_value: false
            ]
          )
        ],
        input_fields: [
          type: list_of(:__inputvalue),
          resolve: fn
            _, %{resolution: %{target: %Type.InputObject{fields: fields} = obj}} ->
              structs = fields |> Map.values
              {:ok, structs}
            _, _ ->
              {:ok, nil}
          end
        ],
        of_type: [type: :__type]
      )
    }
  end

  @absinthe :type
  def __field do
    %Type.Object{
      fields: fields(
        name: [type: :string]
      )
    }
  end

  @absinthe :type
  def __inputvalue do
    %Type.Object{
      fields: fields(
        name: [type: :string],
        description: [type: :string],
        type: [
          type: :__type,
          resolve: fn
            _, %{schema: schema, resolution: %{target: %{type: ident}}} ->
              type = Absinthe.Schema.lookup_type(schema, ident)
              {:ok, type}
          end
        ],
        default_value: [
          type: :string,
          resolve: fn
            _, %{resolution: %{target: %{default_value: value} = t}} ->
              {:ok, value |> to_string}
            _, %{resolution: %{target: target}} ->
              {:ok, nil}
          end
        ]
      )
    }
  end


  # TODO __enumvalue

end
