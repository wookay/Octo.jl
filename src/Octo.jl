module Octo

# package code goes here
include("model.jl")

export SELECT, DISTINCT, FROM, WHERE, LIMIT
export INNER, JOIN, ON
include("clauses.jl")
include("predicate.jl")

export SQL
include("sql.jl")

end # module
