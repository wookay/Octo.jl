module SQL

include("sql_exports.jl")
include("sql_imports.jl")

import .Octo.AdapterBase: Database, Structured, _to_sql, _paramholders

const DatabaseID = Database.SQLDatabase
to_sql(query::Structured)::String = _to_sql(DatabaseID(), query)
paramholders(changes::NamedTuple) = _paramholders(DatabaseID(), changes)

end # Octo.Adapters.SQL
