using Octo
using Test

struct User <: Octo.Model
end

struct Article <: Octo.Model
end

User.table_name = "users"
Article.table_name = "articles"

u = User()
a = Article()

@test SQL.repr[SELECT (a.title, u.age) FROM a INNER JOIN u ON u.id == a.user_id] == "SELECT articles.title, users.age FROM articles INNER JOIN users ON users.id = articles.user_id"

@test SQL.repr[SELECT (a.title, u.age)
               FROM a INNER JOIN u
               ON u.id == a.user_id] == "SELECT articles.title, users.age FROM articles INNER JOIN users ON users.id = articles.user_id"

@test SQL.repr[SELECT DISTINCT (a.title, u.age)
               FROM a INNER JOIN u
               ON u.id == a.user_id] == "SELECT DISTINCT articles.title, users.age FROM articles INNER JOIN users ON users.id = articles.user_id"

@test SQL.repr[SELECT * FROM a INNER JOIN u ON u.id == a.user_id] == "SELECT * FROM articles INNER JOIN users ON users.id = articles.user_id"
@test SQL.repr[SELECT
               *
               FROM
               a
               INNER
               JOIN
               u
               ON
               u.id == a.user_id] == "SELECT * FROM articles INNER JOIN users ON users.id = articles.user_id"

@test SQL.repr[SELECT DISTINCT * FROM a INNER JOIN u ON u.id == a.user_id] == "SELECT DISTINCT * FROM articles INNER JOIN users ON users.id = articles.user_id"
@test SQL.repr[SELECT DISTINCT *
               FROM a INNER JOIN u
               ON u.id == a.user_id] == "SELECT DISTINCT * FROM articles INNER JOIN users ON users.id = articles.user_id"
@test SQL.repr[SELECT
               DISTINCT
               *
               FROM
               a
               INNER
               JOIN
               u
               ON
               u.id == a.user_id] == "SELECT DISTINCT * FROM articles INNER JOIN users ON users.id = articles.user_id"
