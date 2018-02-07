module SQLite

include("sql_exports.jl")

import ..Adapters: Database
import ..Adapters.SQL: Schema, Structured, from, _to_sql, _show
import ..Adapters.SQL: SELECT, DISTINCT, FROM, AS, WHERE, EXISTS, AND, OR, NOT
import ..Adapters.SQL: INNER, OUTER, LEFT, RIGHT, FULL, JOIN, ON, USING
import ..Adapters.SQL: GROUP, BY, HAVING, ORDER, ASC, DESC
import ..Adapters.SQL: COUNT, SUM, AVG

import ..Adapters.SQL: FromClause, SqlPart, sqlrepr, sqlpart

function sqlrepr(db::Database.SQLite, clause::FromClause)::SqlPart
    if clause.__octo_as isa Nothing
         sqlpart(sqlrepr(db, clause.__octo_model))
    else
         sqlpart(sqlrepr.(db, [clause.__octo_model, clause.__octo_as]), " ")
    end
end

const db = Database.SQLite()

to_sql(query::Structured)::String = _to_sql(db, query)
Base.show(io::IO, mime::MIME"text/plain", query::Structured) = _show(io, mime, db, query)

function load(dbfile::String)
    try
        @eval using SQLite
    catch ex
        ex isa ArgumentError && @error ex.msg
    end
end

end # Octo.Adapters.SQLite
