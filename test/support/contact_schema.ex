defmodule ContactSchema do
  use Absinthe.Schema
  alias Absinthe.Type

  @bruce %{name: "Bruce", age: 35}

  def query do
    %Type.Object{
      fields: fields(
        person: [
          type: :person,
          resolve: fn
            _, _ ->
              {:ok, @bruce}
          end
        ],
        contact: [
          type: :contact,
          resolve: fn
            _, _ ->
              {:ok, %{entity: @bruce}}
          end
        ],
        first_search_result: [
          type: :search_result,
          resolve: fn
            _, _ ->
              {:ok, @bruce}
          end
        ]
      )
    }
  end

  def mutation do
    %Type.Object{
      fields: fields(
        person: [
          type: :person,
          args: args(
            profile: [type: :profile_input]
          ),
          resolve: fn
            %{profile: profile} ->
              # Return it like it's a person
              {:ok, profile}
          end
        ]
      )
    }
  end

  @absinthe :type
  def profile_input do
    %Type.InputObject{
      description: "The basic details for a person",
      fields: fields(
        name: [type: :string, description: "The person's name", default_value: "Janet"],
        age: [type: :integer, description: "The person's age", default_value: 43]
      )
    }
  end

  @absinthe :type
  def named_entity do
    %Type.Interface{
      description: "A named entity",
      fields: fields(
        name: [type: :string]
      ),
      resolve_type: fn
        %{age: _}, _ -> :person
        %{employee_count: _}, _ -> :business
      end
    }
  end

  @absinthe :type
  def person do
    %Type.Object{
      description: "A person",
      fields: fields(
        name: [type: :string],
        age: [type: :integer],
        address: deprecate([type: :string], reason: "change of privacy policy")
      ),
      interfaces: [:named_entity]
    }
  end

  @absinthe :type
  def business do
    %Type.Object{
      fields: fields(
        name: [type: :string],
        employee_count: [type: :integer]
      ),
      interfaces: [:named_entity]
    }
  end

  @absinthe :type
  def search_result do
    %Type.Union{
      description: "A search result",
      types: [:business, :person]
    }
  end

  @absinthe :type
  def contact do
    %Type.Object{
      fields: fields(
        entity: [type: :named_entity],
        phone_number: [type: :string],
        address: [type: :string]
      )
    }
  end

end
