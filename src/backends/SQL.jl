module SQLLoader

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
end

# execute
function execute(sql::String)
end

function execute(prepared::String, vals::Vector)::Nothing
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::Nothing
end

end # module Octo.Backends.SQLLoader
