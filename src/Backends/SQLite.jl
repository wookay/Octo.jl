module SQLiteLoader

import SQLite
import Octo.Repo: ExecuteResult

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

# connect
function connect(; kwargs...)
    database = getindex(kwargs, :database)
    db = SQLite.DB(database)
    current[:db] = db
end

# disconnect
function disconnect()
    current[:db] = nothing
end

# query
function query(sql::String)
    db = current_db()
    sink = current_sink()
    SQLite.query(db, sql, sink)
end

function query(prepared::String, vals::Vector)
    db = current_db()
    sink = current_sink()
    SQLite.query(db, prepared, sink; values=vals)
end

# execute
function execute(sql::String)::ExecuteResult
    db = current_db()
    SQLite.query(db, sql)
    ExecuteResult()
end

function execute(prepared::String, vals::Vector)::ExecuteResult
    db = current_db()
    SQLite.query(db, prepared; values=vals)
    ExecuteResult()
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    db = current_db()
    for nt in nts
        SQLite.query(db, prepared; values=values(nt))
    end
    ExecuteResult()
end

end # module Octo.Backends.SQLiteLoader
