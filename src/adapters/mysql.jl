module MySQL

include("sql_exports.jl")

import ..Adapters: Database
import ..Adapters.SQL: Schema, Structured, from, _to_sql, _show
import ..Adapters.SQL: SELECT, DISTINCT, FROM, AS, WHERE, EXISTS, AND, OR, NOT
import ..Adapters.SQL: INNER, OUTER, LEFT, RIGHT, FULL, JOIN, ON, USING
import ..Adapters.SQL: GROUP, BY, HAVING, ORDER, ASC, DESC
import ..Adapters.SQL: COUNT, SUM, AVG

const db = Database.MySQL()

to_sql(query::Structured)::String = _to_sql(db, query)
Base.show(io::IO, mime::MIME"text/plain", query::Structured) = _show(io, mime, db, query)

function load(dbfile::String)
    try
        @eval using MySQL
    catch ex
        ex isa ArgumentError && @error ex.msg
    end
end

end # Octo.Adapters.MySQL
