module MySQL

include("sql_exports.jl")
include("sql_imports.jl")

import .Octo.AdapterBase: Database, Structured, _to_sql, _placeholder, _placeholders
import .Octo: @keywords

const DatabaseID = Database.MySQLDatabase

"""
    to_sql
"""
to_sql(query::Structured)::String = _to_sql(DatabaseID(), query)

placeholder(nth::Int) = _placeholder(DatabaseID(), nth)
placeholders(dims::Int) = _placeholders(DatabaseID(), dims)

export    USE
@keywords USE

end # Octo.Adapters.MySQL