module SQLiteLoader

# https://github.com/JuliaDatabases/SQLite.jl
using SQLite # SQLite.jl v0.7.0
using Octo.Repo: ExecuteResult

const current = Dict{Symbol, Any}(
    :db => nothing,
    :sink => Vector{<:NamedTuple}, # DataFrames.DataFrame
)

current_db() = current[:db]
current_sink() = current[:sink]

# sink
function sink(T::Type)
   current[:sink] = T
end

# db_connect
function db_connect(; kwargs...)
    database = getindex(kwargs, :database)
    db = SQLite.DB(database)
    current[:db] = db
end

# db_disconnect
function db_disconnect()
    current[:db] = nothing
end

# query
function query(sql::String)
    db = current_db()
    table = SQLite.Query(db, sql)
    collect(table)
end

function query(prepared::String, vals::Vector)
    db = current_db()
    table = SQLite.Query(db, prepared; values=vals)
    collect(table)
end

# execute
function execute(sql::String)::ExecuteResult
    db = current_db()
    SQLite.Query(db, sql)
    ExecuteResult()
end

function execute(prepared::String, vals::Vector)::ExecuteResult
    db = current_db()
    SQLite.Query(db, prepared; values=vals)
    ExecuteResult()
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    db = current_db()
    for nt in nts
        SQLite.Query(db, prepared; values=values(nt))
    end
    ExecuteResult()
end

end # module Octo.Backends.SQLiteLoader
