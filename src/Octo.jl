__precompile__(true)

module Octo

include("types.jl")
include("Schema.jl")
include("Queryable.jl")
include("predicates.jl")
include("Backends.jl")
include("adapter_base.jl")
include("Repo.jl")
include("Adapters.jl")

end # module Octo
