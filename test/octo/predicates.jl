module octo_predicates

using Test
using Octo.Adapters.SQL # from to_sql
using Octo: Enclosed

struct T
end

t = from(T)
enc = Enclosed([])
@test to_sql([t.name == enc]) == "name = ()"

end # module octo_predicates
