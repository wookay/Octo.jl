module SQLLoader

using Octo.Repo: SQLKeyword, ExecuteResult

# db_connect
function db_connect(; kwargs...)
end

# db_disconnect
function db_disconnect()
end

# query
function query(sql::String)
end

function query(prepared::String, vals::Vector)
end

# execute
function execute(sql::String)::ExecuteResult
    ExecuteResult()
end

function execute(prepared::String, vals::Vector)::ExecuteResult
    ExecuteResult()
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    ExecuteResult()
end

# execute_result
function execute_result(command::SQLKeyword)::ExecuteResult
    ExecuteResult()
end

end # module Octo.Backends.SQLLoader
