module Octo

# package code goes here
include("model.jl")

export SELECT, FROM
include("clauses.jl")

export SQL
include("sql.jl")

end # module
