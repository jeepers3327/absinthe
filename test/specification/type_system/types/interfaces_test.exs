defmodule Specification.TypeSystem.Types.InterfacesTest do
  use ExSpec, async: true
  @moduletag :specification

  @graphql_spec "#sec-Interfaces"

  describe "an object that implements an interface" do

    describe "when it defines those field" do

      defmodule GoodSchema do
        use Absinthe.Schema
        alias Absinthe.Type

        def query do
          %Type.Object{
            fields: fields(
              foo: [type: :foo],
              bar: [type: :bar],
              named_thing: [
                type: :named,
              ]
            )
          }
        end

        @absinthe :type
        def foo do
          %Type.Object{
            fields: fields(
              name: [type: :string]
            ),
            is_type_of: fn _ -> true end,
            interfaces: [:named]
          }
        end

        @absinthe :type
        def bar do
          %Type.Object{
            fields: fields(
              name: [type: :string]
            ),
            is_type_of: fn _ -> true end,
            interfaces: [:named]
          }
        end

        # NOT USED IN THE SCHEMA
        @absinthe :type
        def baz do
          %Type.Object{
            fields: fields(
              name: [type: :string]
            ),
            interfaces: [:named]
          }
        end

        @absinthe :type
        def named do
          %Type.Interface{
            fields: fields(
              name: [type: :string]
            )
          }
        end
      end

      it "causes no schema errors" do
        assert %{errors: []} = GoodSchema.schema
      end

      it "captures the relationships in the schema" do
        schema = GoodSchema.schema
        assert :foo in schema.interfaces[:named]
        assert :bar in schema.interfaces[:named]
      end

      it "does not captures the relationships not in the schema" do
        schema = GoodSchema.schema
        assert not :baz in schema.interfaces[:named]
      end


    end

    describe "when it doesn't define those fields" do

      defmodule BadSchema do
        use Absinthe.Schema
        alias Absinthe.Type

        def query do
          %Type.Object{
            fields: fields(
              foo: [type: :foo],
              quux: [type: :quux],
              spam: [type: :spam]
            )
          }
        end

        # Bad implementation
        @absinthe :type
        def foo do
          %Type.Object{
            fields: fields(
              not_name: [type: :string]
            ),
            interfaces: [:named],
            is_type_of: fn _ -> true end
          }
        end

        # Not a good interface type
        @absinthe :type
        def quux do
          %Type.Object{
            fields: fields(
              not_name: [type: :string]
            ),
            interfaces: [:foo],
            is_type_of: fn _ -> true end
          }
        end

        # Doesn't have an is_type_of, and the Interface has no resolve_type
        @absinthe :type
        def spam do
          %Type.Object{
            fields: fields(
              name: [type: :string]
            ),
            interfaces: [:named]
          }
        end

        @absinthe :type
        def named do
          %Type.Interface{
            fields: fields(
              name: [type: :string]
            )
          }
        end
      end

      it "causes schema errors" do
        %{errors: errors} = BadSchema.schema
        assert [
          "The :foo object type does not implement the :named interface type, as declared",
          "The :quux object type may only implement Interface types, it cannot implement :foo (Object)",
          "Interface type :named does not provide a `resolve_type` function and implementing type :spam does not provide an `in_type_of` function. There is no way to resolve this implementing type during execution."
        ] |> Enum.sort == Enum.sort(errors)
      end
    end
  end

end
