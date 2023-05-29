module test_octo_structured

using Test
using Octo.Adapters.SQL # from to_sql

# IN
@test to_sql([IN ("Germany", "France", "UK")]) == "IN ('Germany', 'France', 'UK')"

struct Customer
end
Schema.model(Customer, table_name="Customers")

customers = from(Customer)

@test to_sql([FROM Customer]) == "FROM Customers"

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


# https://dba.stackexchange.com/questions/21749/count-with-set-difference-and-union
struct Tbl1
end
Schema.model(Tbl1, table_name="tbl1")

struct Tbl2
end
Schema.model(Tbl2, table_name="tbl2")

struct Tbl3
end
Schema.model(Tbl3, table_name="tbl3")

tbl1 = from(Tbl1, :tbl1)
tbl2 = from(Tbl2, :tbl2)
tbl3 = from(Tbl3, :tbl3)
subexcept = from([SELECT tbl2.id FROM tbl2 UNION SELECT tbl3.id FROM tbl3])
sub = from([SELECT tbl1.id FROM tbl1 EXCEPT subexcept], :t)
@test to_sql([SELECT COUNT(*) FROM sub]) == "SELECT COUNT(*) FROM (SELECT tbl1.id FROM tbl1 EXCEPT (SELECT tbl2.id FROM tbl2 UNION SELECT tbl3.id FROM tbl3)) AS t"

sub = from([SELECT tbl1.id FROM tbl1 EXCEPT SELECT tbl2.id FROM tbl2 EXCEPT SELECT tbl3.id FROM tbl3], :t)
@test to_sql([SELECT COUNT(*) FROM sub]) == "SELECT COUNT(*) FROM (SELECT tbl1.id FROM tbl1 EXCEPT SELECT tbl2.id FROM tbl2 EXCEPT SELECT tbl3.id FROM tbl3) AS t"

# Issue #13
struct User
end
Schema.model(User, table_name="users")
users = from(User)
@test to_sql([INSERT INTO users (users.name, users.email) VALUES ("Jick", "Jick@dd.com")]) == "INSERT INTO users (name, email) VALUES ('Jick', 'Jick@dd.com')"
users = from(User, :users)
@test to_sql([INSERT INTO users (users.name, users.email) VALUES ("Jick", "Jick@dd.com")]) == "INSERT INTO users (name, email) VALUES ('Jick', 'Jick@dd.com')"
@test to_sql([INSERT INTO users (:name, :email) VALUES ("Jick", "Jick@dd.com")]) == "INSERT INTO users (name, email) VALUES ('Jick', 'Jick@dd.com')"

# Issue #54
struct MyTable
end
Schema.model(MyTable, table_name="mytable")
e = from(MyTable)
dataSource = "test"
df = to_sql([
    SELECT (e.name, e.age)
    FROM MyTable
    WHERE e.data_source==dataSource
])

end # module test_octo_structured
