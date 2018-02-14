module MySQL

include("sql_exports.jl")
include("sql_imports.jl")

import .Octo.AdapterBase: Database, Structured, _to_sql

const DatabaseID = Database.MySQLDatabase
to_sql(query::Structured)::String = _to_sql(DatabaseID(), query)

import .Octo.AdapterBase: @keywords

export    USE, DATABASE
@keywords USE  DATABASE

end # Octo.Adapters.MySQL
