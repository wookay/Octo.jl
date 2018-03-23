module octo_predicates

using Test
using Octo.Adapters.SQL # from to_sql
using Octo: Enclosed

struct User
end

u = from(User)
enc = Enclosed([])
@test to_sql([u.name == enc]) == "name = ()"

@test to_sql([u.name IS NOT NULL]) == "name IS NOT NULL"
@test to_sql([30 >= u.age AND u.age >= 20]) == "30 >= age AND age >= 20"

end # module octo_predicates
