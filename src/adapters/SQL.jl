module SQL

include("sql_exports.jl")
include("sql_imports.jl")

import .Octo.AdapterBase: Database, Structured, _to_sql

const DatabaseID = Database.SQLDatabase
to_sql(query::Structured)::String = _to_sql(DatabaseID(), query)

end # Octo.Adapters.SQL
