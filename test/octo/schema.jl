module octo_schema

using Test # @test_throws
using Octo.Adapters.SQL # Schema.changeset Repo
using Octo.Schema # InvalidChangesetError validate_length

struct User
end
Schema.model(User, table_name="users")

Schema.changeset(User) do model
    validate_length(model, :username, min=6)
end

Repo.connect(adapter=Octo.Adapters.SQL)

Repo.insert!(User, (username="abcdef",))
@test_throws InvalidChangesetError Repo.insert!(User, (username="a",))

end # module octo_schema
