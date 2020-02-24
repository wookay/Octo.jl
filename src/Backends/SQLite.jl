module SQLiteLoader

# https://github.com/JuliaDatabases/SQLite.jl
using SQLite # SQLite.jl v1.0.2
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
    (SQLite.rowtable ∘ SQLite.DBInterface.execute)(db, sql)
end

function query(prepared::String, vals::Vector)
    db = current_db()
    SQLite.rowtable(SQLite.DBInterface.execute(db, prepared, vals))
end

# execute
function execute(sql::String)::ExecuteResult
    db = current_db()
    SQLite.DBInterface.execute(db, sql)
    ExecuteResult()
end

function execute(prepared::String, vals::Vector)::ExecuteResult
    db = current_db()
    SQLite.DBInterface.execute(db, prepared, vals)
    ExecuteResult()
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    db = current_db()
    for nt in nts
        SQLite.DBInterface.execute(db, prepared, values(nt))
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
