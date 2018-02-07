module MySQL

include("sql_exports.jl")
include("sql_imports.jl")

import ..Adapters: Database
import ..Adapters.SQL: Structured, _to_sql, _show

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
