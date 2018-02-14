module MySQL

include("sql_exports.jl")
include("sql_imports.jl")

import .Octo.AdapterBase: Database, Structured, _to_sql, _paramholders

const DatabaseID = Database.MySQLDatabase
to_sql(query::Structured)::String = _to_sql(DatabaseID(), query)
paramholders(changes::NamedTuple) = _paramholders(DatabaseID(), changes)

import .Octo.AdapterBase: @keywords

export    USE
@keywords USE

end # Octo.Adapters.MySQL
