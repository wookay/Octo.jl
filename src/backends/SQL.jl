module SQLLoader

# load
function load(; kwargs...)
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

function execute(sql::String, values::Tuple)
end

end # module Octo.Backends.SQLLoader
