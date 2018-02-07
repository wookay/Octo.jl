module SQLite

include("sql_exports.jl")
include("sql_imports.jl")

import ..Adapters: Database
import ..Adapters.SQL: Structured, _to_sql, _show

import ..Adapters.SQL: FromClause, SqlPart, sqlrepr, sqlpart
const DB = Database.SQLite

function sqlrepr(db::DB, clause::FromClause)::SqlPart
    if clause.__octo_as isa Nothing
         sqlpart(sqlrepr(db, clause.__octo_model))
    else
         sqlpart(sqlrepr.(db, [clause.__octo_model, clause.__octo_as]), " ")
    end
end

to_sql(query::Structured)::String = _to_sql(DB(), query)
Base.show(io::IO, mime::MIME"text/plain", query::Structured) = _show(io, mime, DB(), query)

function load(dbfile::String)
    try
        @eval using SQLite
    catch ex
        ex isa ArgumentError && @error ex.msg
    end
end

end # Octo.Adapters.SQLite
