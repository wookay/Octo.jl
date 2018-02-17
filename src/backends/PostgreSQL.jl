module PostgreSQLLoader

import PostgreSQL

const current = Dict{Symbol, Union{Nothing, PostgreSQL.PostgresDatabaseHandle}}(
    :conn => nothing
)

current_conn() = current[:conn]

# load
function load(; kwargs...)
    args = (:hostname, :username, :password)
    (hostname, username, password) = getindex.(kwargs, args)
    options = filter(kv -> !(kv.first in (args..., :database)), kwargs)
    if haskey(kwargs, :database)
        conn = PostgreSQL.connect(PostgreSQL.Postgres, hostname, username, password, kwargs[:database]; options...)
    else
        conn = PostgreSQL.connect(PostgreSQL.Postgres, hostname, username, password; options...)
    end
    current[:conn] = conn
end

# disconnect
function disconnect()
    conn = current_conn()
    PostgreSQL.disconnect(conn)
    current[:conn] = nothing
end

# query
function query(sql::String)
    conn = current_conn()
    stmt = PostgreSQL.prepare(conn, sql)
    result = PostgreSQL.execute(stmt)
    df = PostgreSQL.fetchdf(result)
    PostgreSQL.finish(stmt)
    df
end

# execute
function execute(sql::String)
    conn = current_conn()
    PostgreSQL.run(conn, sql)
end

function execute(sql::String, tups::Vector{Tuple})
    conn = current_conn()
    stmt = PostgreSQL.prepare(conn, sql)
    for tup in tups
        PostgreSQL.execute(stmt, collect(tup))
    end
    PostgreSQL.finish(stmt)
end

end # module Octo.Backends.PostgreSQLLoader
