module PostgreSQL

include("sql_exports.jl")
include("sql_imports.jl")

import .Octo.AdapterBase: Database, Structured, _to_sql

const DatabaseID = Database.PostgreSQLDatabase
to_sql(query::Structured)::String = _to_sql(DatabaseID(), query)
placeholder(nth::Int) = PlaceHolder("\$$nth")
placeholders(dims::Int) = Enclosed([PlaceHolder("\$$x") for x in 1:dims])

import .Octo.AdapterBase: FromClause, SqlPart, sqlrepr, sqlpart
function sqlrepr(db::DatabaseID, clause::FromClause)::SqlPart
    if clause.__octo_as isa Nothing
         sqlpart(sqlrepr(db, clause.__octo_model))
    else
         sqlpart(sqlrepr.(db, [clause.__octo_model, clause.__octo_as]), " ")
    end
end

end # Octo.Adapters.PostgreSQL
