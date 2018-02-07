module PostgreSQL

include("sql_exports.jl")

import ..Adapters: Database
import ..Adapters.SQL: Schema, Structured, from, _to_sql, _show
import ..Adapters.SQL: SELECT, DISTINCT, FROM, AS, WHERE, LIKE, EXISTS, AND, OR, NOT, LIMIT, OFFSET, INTO
import ..Adapters.SQL: INNER, OUTER, LEFT, RIGHT, FULL, JOIN, ON, USING
import ..Adapters.SQL: GROUP, BY, HAVING, ORDER, ASC, DESC
import ..Adapters.SQL: COUNT, SUM, AVG

import ..Adapters.SQL: FromClause, SqlPart, sqlrepr, sqlpart
const DB = Database.PostgreSQL

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
        @eval using PostgreSQL
    catch ex
        ex isa ArgumentError && @error ex.msg
    end
end

end # Octo.Adapters.PostgreSQL
