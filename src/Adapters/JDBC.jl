module JDBC

include("sql_exports.jl")
include("sql_imports.jl") # Database Structured SubQuery WindowFrame _to_sql _placeholders
import .Octo.Queryable: window #

const DatabaseID = Database.JDBCDatabase

to_sql(query::Structured)::String = _to_sql(DatabaseID(), query)
to_sql(subquery::SubQuery)::String = _to_sql(DatabaseID(), subquery)
to_sql(frame::WindowFrame)::String = _to_sql(DatabaseID(), frame)

placeholder(nth::Int) = _placeholder(DatabaseID(), nth)
placeholders(dims::Int) = _placeholders(DatabaseID(), dims)

end # Octo.Adapters.JDBC
