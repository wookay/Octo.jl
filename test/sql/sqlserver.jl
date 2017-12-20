using Octo
using Test

struct Title <: Octo.Model
end

struct Publisher <: Octo.Model
end

Title.table_name = "titles"
Publisher.table_name = "publishers"

t = Title()
p = Publisher()

@test SQL.repr[SELECT (t.pub_id, AVG(t.price)) FROM t INNER JOIN p ON t.pub_id == p.pub_id] == "SELECT titles.pub_id, AVG(titles.price) FROM titles INNER JOIN publishers ON titles.pub_id = publishers.pub_id"
@test SQL.repr[SELECT (t.pub_id, AVG(t.price))
              FROM t INNER JOIN p
              ON t.pub_id == p.pub_id] == "SELECT titles.pub_id, AVG(titles.price) FROM titles INNER JOIN publishers ON titles.pub_id = publishers.pub_id"

@test SQL.repr[SELECT (t.pub_id, AVG(t.price))
               FROM t INNER JOIN p
               ON t.pub_id == p.pub_id
               WHERE p.state == "CA"
               GROUP BY t.pub_id
               HAVING AVG(t.price) > 10] == "SELECT titles.pub_id, AVG(titles.price) FROM titles INNER JOIN publishers ON titles.pub_id = publishers.pub_id WHERE publishers.state = 'CA' GROUP BY titles.pub_id HAVING AVG(titles.price) > 10"
