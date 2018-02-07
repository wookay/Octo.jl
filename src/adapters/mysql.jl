module MySQL

include("sql_exports.jl")

import ..Adapters: Database
import ..Adapters.SQL: Schema, Structured, from, _to_sql, _show
import ..Adapters.SQL: SELECT, DISTINCT, FROM, AS, WHERE, LIKE, EXISTS, AND, OR, NOT, LIMIT, OFFSET, INTO
import ..Adapters.SQL: INNER, OUTER, LEFT, RIGHT, FULL, JOIN, ON, USING
import ..Adapters.SQL: GROUP, BY, HAVING, ORDER, ASC, DESC
import ..Adapters.SQL: COUNT, SUM, AVG

const DB = Database.MySQL

to_sql(query::Structured)::String = _to_sql(DB(), query)
Base.show(io::IO, mime::MIME"text/plain", query::Structured) = _show(io, mime, DB(), query)

function load(dbfile::String)
    try
        @eval using MySQL
    catch ex
        ex isa ArgumentError && @error ex.msg
    end
end

end # Octo.Adapters.MySQL
