module test_octo_schema

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


Schema.model(User, table_name="users", primary_keys=("pk1", "pk2"))
Repo.get(User, (pk1=1, pk2=2))

end # module test_octo_schema
