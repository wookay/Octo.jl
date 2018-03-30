module test_octo_structured

using Test
using Octo.Adapters.SQL # from to_sql

# IN
@test to_sql([IN ("Germany", "France", "UK")]) == "IN ('Germany', 'France', 'UK')"

struct Customer
end
Schema.model(Customer, table_name="Customers")

customers = from(Customer)

# IN
@test to_sql([customers.Country IN ("Germany", "France", "UK")]) == "Country IN ('Germany', 'France', 'UK')"
@test to_sql([customers.Country NOT IN ("Germany", "France", "UK")]) == "Country NOT IN ('Germany', 'France', 'UK')"

end # module test_octo_structured
