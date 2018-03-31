__precompile__(true)

module Octo

include("Deps.jl")
include("types.jl")
include("macros.jl")
include("Schema.jl")
include("Queryable.jl")
include("predicates.jl")
include("Backends.jl")
include("AdapterBase.jl")
include("Pretty.jl")
include("Repo.jl")
include("Adapters.jl")

end # module Octo
