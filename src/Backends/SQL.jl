module SQLLoader

using Octo.Repo: SQLKeyword, ExecuteResult

# db_dbname
function db_dbname(nt::NamedTuple)::String
    ""
end

# db_connect
function db_connect(; kwargs...)
end

# db_disconnect
function db_disconnect(conn)
end

# query
function query(conn, sql::String)
end

function query(conn, prepared::String, vals::Vector)
end

# execute
function execute(conn, sql::String)::ExecuteResult
    ExecuteResult()
end

function execute(conn, prepared::String, vals::Vector)::ExecuteResult
    ExecuteResult()
end

function execute(conn, prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    ExecuteResult()
end

# execute_result
function execute_result(conn, command::SQLKeyword)::ExecuteResult
    ExecuteResult()
end

end # module Octo.Backends.SQLLoader
