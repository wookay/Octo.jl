module SQLiteLoader

import SQLite

const current = Dict{Symbol, Union{Nothing, SQLite.DB}}(
    :db => nothing
)

function load(; kwargs...)
    database = getindex(kwargs, :database)
    db = SQLite.DB(database)
    current[:db] = db
end

current_db() = current[:db]

# query
function query(sql::String)
    db = current_db()
    SQLite.query(db, sql)
end

# execute
function execute(sql::String)
    query(sql)
end

function execute(sql::String, values::Tuple)
    db = current_db()
    SQLite.query(db, sql; values=values)
end

end # module Octo.Backends.SQLiteLoader
