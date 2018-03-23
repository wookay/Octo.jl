module SQLite

include("sql_exports.jl")
include("sql_imports.jl")

import .Octo.AdapterBase: Database, Structured, _to_sql, _placeholder, _placeholders

const DatabaseID = Database.SQLiteDatabase

"""
    to_sql
"""
to_sql(query::Structured)::String = _to_sql(DatabaseID(), query)

placeholder(nth::Int) = _placeholder(DatabaseID(), nth)
placeholders(dims::Int) = _placeholders(DatabaseID(), dims)

import .Octo.AdapterBase: FromClause, SqlPart, sqlrepr, sqlpart
function sqlrepr(db::DatabaseID, clause::FromClause)::SqlPart
    if clause.__octo_as isa Nothing
         sqlpart(sqlrepr(db, clause.__octo_model))
    else
         sqlpart(sqlrepr.(Ref(db), [clause.__octo_model, clause.__octo_as]), " ")
    end
end

end # Octo.Adapters.SQLite
