module JDBCLoader

# https://github.com/JuliaDatabases/JDBC.jl
import JDBC
import Octo.Repo: ExecuteResult
import Octo.Backends: UnsupportedError

# sink
function sink(::Type)
end

# db_connect
function db_connect(; kwargs...)
end

# db_disconnect
function db_disconnect()
end

# query
function query(sql::String)
    throw(UnsupportedError("needs to be implemented"))
end

function query(prepared::String, vals::Vector)
    throw(UnsupportedError("needs to be implemented"))
end

# execute
function execute(sql::String)::ExecuteResult
    throw(UnsupportedError("needs to be implemented"))
end

function execute(prepared::String, vals::Vector)::ExecuteResult
    throw(UnsupportedError("needs to be implemented"))
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    throw(UnsupportedError("needs to be implemented"))
end

end # module Octo.Backends.JDBCLoader
