module SQLite

include("sql_exports.jl")
include("sql_imports.jl") # Database Structured SubQuery _to_sql _placeholder _placeholders

const DatabaseID = Database.SQLiteDatabase

"""
    to_sql(query::Structured)::String
"""
to_sql(query::Structured)::String = _to_sql(DatabaseID(), query)

"""
    to_sql(subquery::SubQuery)::String
"""
to_sql(subquery::SubQuery)::String = _to_sql(DatabaseID(), subquery)

placeholder(nth::Int) = _placeholder(DatabaseID(), nth)
placeholders(dims::Int) = _placeholders(DatabaseID(), dims)

import .Octo.AdapterBase: FromClause, SqlPart, sqlrepr, _sqlrepr
function sqlrepr(db::DatabaseID, clause::FromClause)::SqlPart
    _sqlrepr(db, clause; with_as=false)
end

window(query::Structured, as::Union{Nothing,Symbol}=nothing) = @warn "SQLite does not support"

end # Octo.Adapters.SQLite
