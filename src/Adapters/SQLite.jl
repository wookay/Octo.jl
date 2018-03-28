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

import .Octo.AdapterBase: FromClause, SqlPart, sqlrepr
function sqlrepr(db::DatabaseID, clause::FromClause)::SqlPart
    if clause.__octo_as isa Nothing
         els = [clause.__octo_model]
    else
         els = [clause.__octo_model, clause.__octo_as]
    end
    SqlPart(sqlrepr.(Ref(db), els), " ")
end

window(query::Structured, as::Union{Nothing,Symbol}=nothing) = @warn "SQLite does not support"

end # Octo.Adapters.SQLite
