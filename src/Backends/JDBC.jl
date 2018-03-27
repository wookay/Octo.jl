module JDBCLoader

# https://github.com/JuliaDatabases/JDBC.jl
import JDBC
import Octo.Backends: UnsupportedError

# sink
function sink(::Type)
end

# connect
function connect(; kwargs...)
end

# disconnect
function disconnect()
end

# query
function query(sql::String)
    throw(UnsupportedError("needs to be implemented"))
end

function query(prepared::String, vals::Vector)
    throw(UnsupportedError("needs to be implemented"))
end

# execute
function execute(sql::String)
    throw(UnsupportedError("needs to be implemented"))
end

function execute(prepared::String, vals::Vector)::Nothing
    throw(UnsupportedError("needs to be implemented"))
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::Nothing
    throw(UnsupportedError("needs to be implemented"))
end

end # module Octo.Backends.JDBCLoader
