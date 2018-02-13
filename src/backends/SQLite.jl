module SQLiteLoader

import SQLite

const current = Dict{Symbol, Union{Nothing, SQLite.DB}}(
    :db => nothing
)

function load(database::String)
    db = SQLite.DB(database)
    current[:db] = db
end

current_db() = current[:db]

function query(sql::String)
    db = current_db()
    SQLite.query(db, sql)
end

function query(sql::String, values::Vector)
    db = current_db()
    SQLite.query(db, sql; values=values)
end

end # module Octo.Backends.SQLiteLoader
