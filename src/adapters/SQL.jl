module SQL

include("sql_exports.jl")
include("sql_imports.jl")

import .Octo.AdapterBase: Database, Structured, _to_sql, _placeholder, _placeholders

const DatabaseID = Database.SQLDatabase
to_sql(query::Structured)::String = _to_sql(DatabaseID(), query)
placeholder(nth::Int) = _placeholder(DatabaseID(), nth)
placeholders(dims::Int) = _placeholders(DatabaseID(), dims)

end # Octo.Adapters.SQL
