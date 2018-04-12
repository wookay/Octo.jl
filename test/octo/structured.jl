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

@test to_sql([WHERE true]) == "WHERE true"
@test to_sql([1,2,3]) == "1 2 3"
@test to_sql([(1,2,3)]) == "1, 2, 3"


struct Department
end
Schema.model(Department, table_name="departments")
struct Employee
end
Schema.model(Employee, table_name="employees")
d = from(Department)
em = from(Employee)
sub = from([SELECT d.department_id FROM d WHERE d.location_id == 1800])
q = [SELECT (em.first_name, em.last_name, em.department_id) FROM em WHERE em.department_id IN sub]
@test to_sql(q) == "SELECT first_name, last_name, department_id FROM employees WHERE department_id IN (SELECT department_id FROM departments WHERE location_id = 1800)"

end # module test_octo_structured
