module SQLiteLoader

# https://github.com/JuliaDatabases/SQLite.jl
using SQLite # SQLite.jl 1.6
using .SQLite: Tables, DBInterface

using Octo: Repo, AdapterBase, DBMS, SQLElement, Structured
using .Repo: SQLKeyword, ExecuteResult, sql_startswith_insert_update_delete
using .AdapterBase: INSERT

# db_dbname
function db_dbname(nt::NamedTuple)::String
    (last ∘ splitdir)(nt.dbfile)
end

# db_connect
function db_connect(; kwargs...)
    dbfile = getindex(kwargs, :dbfile)
    SQLite.DB(dbfile)
end

# db_disconnect
function db_disconnect(db)
    DBInterface.close!(db)
end

# query
function query(db, sql::String)
    q = DBInterface.execute(db, sql)
    Tables.rowtable(q)
end

function query(db, prepared::String, vals::Vector)
    stmt = DBInterface.prepare(db, prepared)
    q = DBInterface.execute(stmt, vals)
    Tables.rowtable(q)
end

# execute
function execute(db, sql::String)::ExecuteResult
    DBInterface.execute(db, sql)
    sql_startswith_insert_update_delete_then_get_num_affected_rows(sql, db)
end

function execute(db, prepared::String, vals::Vector)::ExecuteResult
    stmt = DBInterface.prepare(db, prepared)
    DBInterface.execute(stmt, vals)
    sql_startswith_insert_update_delete_then_get_num_affected_rows(prepared, db)
end

function execute(db, prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    stmt = DBInterface.prepare(db, prepared)
    num_affected_rows = 0
    for nt in nts
        DBInterface.execute(stmt, values(nt))
        num_affected_rows += get_num_affected_rows(db)
    end
    (num_affected_rows=num_affected_rows,)
end

function sql_startswith_insert_update_delete_then_get_num_affected_rows(sql::String, db)
    if sql_startswith_insert_update_delete(sql)
        num_affected_rows = get_num_affected_rows(db)
        (num_affected_rows=num_affected_rows,)
    else
        nothing
    end
end

function get_num_affected_rows(db)::Int
    SQLite.C.sqlite3_changes(db.handle)
end

# execute_result
function execute_result(db, command::SQLKeyword)::NamedTuple
    if INSERT === command
        last_insert_id = SQLite.last_insert_rowid(db)
        (id=last_insert_id,)
    else
        NamedTuple()
    end
end

function Base.show(io::IO, mime::MIME"text/plain", element::Union{E,Structured} where E<:SQLElement)
    dbms = DBMS.SQLite()
    AdapterBase._show(io, mime, dbms, element)
end

end # module Octo.Backends.SQLiteLoader
