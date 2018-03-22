module SQLiteLoader

import SQLite

const current = Dict{Symbol, Any}(
    :db => nothing,
    :sink => NamedTuple,
)

current_db() = current[:db]
current_sink() = current[:sink]

# sink
function sink(T::Type)
   current[:sink] = T
end

# load
function load(; kwargs...)
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

# execute
function execute(sql::String)::Nothing
    db = current_db()
    SQLite.query(db, sql)
    nothing
end

function execute(prepared::String, vals::Vector)::Nothing
    db = current_db()
    SQLite.query(db, prepared; values=vals)
    nothing
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::Nothing
    db = current_db()
    for nt in nts
        SQLite.query(db, prepared; values=values(nt))
    end
    nothing
end

end # module Octo.Backends.SQLiteLoader
