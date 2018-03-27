module JDBC

include("sql_exports.jl")
include("sql_imports.jl")

import .Octo.AdapterBase: Database, Structured, SubQuery, _to_sql

const DatabaseID = Database.JDBCDatabase

to_sql(query::Structured)::String = _to_sql(DatabaseID(), query)
to_sql(subquery::SubQuery)::String = _to_sql(DatabaseID(), subquery)

end # Octo.Adapters.JDBC
