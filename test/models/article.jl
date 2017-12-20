using Octo
using Test

struct Article <: Octo.Model
end

Article.table_name = "articles"

a = Article()

@test SQL.repr[a] == "articles"
@test SQL.repr[FROM a] == "FROM articles"
@test SQL.repr[SELECT * FROM a] == "SELECT * FROM articles"
@test SQL.repr[SELECT a.title FROM a] == "SELECT title FROM articles"
