module SQLiteLoader

import SQLite

const current = Dict{Symbol, Union{Nothing, SQLite.DB}}(
    :db => nothing
)

current_db() = current[:db]

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
    SQLite.query(db, sql)
end

# execute
function execute(sql::String)
    query(sql)
end

function execute(sql::String, tups::Vector{Tuple})
    db = current_db()
    for tup in tups
        SQLite.query(db, sql; values=tup)
    end
end

end # module Octo.Backends.SQLiteLoader
