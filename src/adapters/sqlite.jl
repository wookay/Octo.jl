module SQLite

import ..Adapters: Database
import ..Adapters.SQL: Statement, sqlrepr, FromClause, sqlstring
import ..Adapters.SQL: SELECT, FROM, AS, WHERE

export to_sql
export SELECT, FROM, AS, WHERE

function sqlrepr(db::Database.SQLite, clause::FromClause)
    clause.__octo_as isa Nothing ? sqlrepr(db, clause.__octo_model) :
                                   sqlrepr.(db, [clause.__octo_model, clause.__octo_as])
end

function to_sql(stmt::Statement)
    sqlstring(vcat(sqlrepr.(Database.SQLite(), stmt)...))
end

function load(dbfile::String)
    try
        @eval using SQLite2
    catch ex
        ex isa ArgumentError && @error ex.msg
    end
end

end # Octo.Adapters.SQLite
