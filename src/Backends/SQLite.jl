module SQLiteLoader

# https://github.com/JuliaDatabases/SQLite.jl
using SQLite # SQLite.jl v1.0.2
using .SQLite: Tables, DBInterface
using Octo.Repo: SQLKeyword, ExecuteResult
using Octo.AdapterBase: INSERT

const current = Dict{Symbol, Any}(
    :db => nothing,
)

current_db() = current[:db]

# db_connect
function db_connect(; kwargs...)
    dbfile = getindex(kwargs, :dbfile)
    db = SQLite.DB(dbfile)
    current[:db] = db
end

# db_disconnect
function db_disconnect()
    current[:db] = nothing
end

# query
function query(sql::String)
    db = current_db()
    (Tables.rowtable ∘ DBInterface.execute)(db, sql)
end

function query(prepared::String, vals::Vector)
    db = current_db()
    stmt = DBInterface.prepare(db, prepared)
    (Tables.rowtable ∘ DBInterface.execute)(stmt, vals)
end

# execute
function execute(sql::String)::ExecuteResult
    db = current_db()
    DBInterface.execute(db, sql)
    ExecuteResult()
end

function execute(prepared::String, vals::Vector)::ExecuteResult
    db = current_db()
    stmt = DBInterface.prepare(db, prepared)
    DBInterface.execute(stmt, vals)
    ExecuteResult()
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    db = current_db()
    stmt = DBInterface.prepare(db, prepared)
    for nt in nts
        DBInterface.execute(stmt, values(nt))
    end
    ExecuteResult()
end

# execute_result
function execute_result(command::SQLKeyword)::ExecuteResult
    if INSERT === command
        db = current_db()
        last_insert_id = SQLite.last_insert_rowid(db)
        (id=last_insert_id,)
    end
end

end # module Octo.Backends.SQLiteLoader
