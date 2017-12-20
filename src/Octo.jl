module Octo

# package code goes here
include("model.jl")

export SELECT, FROM
export INNER, JOIN, ON
include("clauses.jl")

export SQL
include("sql.jl")

end # module
