module SQLite

import ..Adapters: Database
import ..Adapters.SQL: FromClause, Structured, SqlPart, sqlrepr, sqlpart, _to_sql, _show
import ..Adapters.SQL: SELECT, FROM, AS, WHERE, AND, OR, NOT

export to_sql
export SELECT, FROM, AS, WHERE, AND, OR, NOT

function sqlrepr(db::Database.SQLite, clause::FromClause)::SqlPart
    if clause.__octo_as isa Nothing
         sqlpart(sqlrepr(db, clause.__octo_model))
    else
         sqlpart(sqlrepr.(db, [clause.__octo_model, clause.__octo_as]), " ")
    end
end

to_sql(query::Structured)::String = _to_sql(Database.SQLite(), query)
Base.show(io::IO, mime::MIME"text/plain", query::Structured) = _show(io, mime, Database.SQLite(), query)

function load(dbfile::String)
    try
        @eval using SQLite2
    catch ex
        ex isa ArgumentError && @error ex.msg
    end
end

end # Octo.Adapters.SQLite
