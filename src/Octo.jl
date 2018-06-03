__precompile__(true)
module Octo

include("Deps.jl")
include("types.jl")
include("macros.jl")     # @sql_keywords @sql_functions
include("Schema.jl")     # Schema.model Schema.changeset
include("Queryable.jl")  # Queryable: from, as, window
include("predicates.jl")
include("Backends.jl")
include("AdapterBase.jl")
include("Pretty.jl")     # Pretty # Tablize Vector{<:NamedTuple}
include("Repo.jl")       # Repo
include("Adapters.jl")

end # module Octo
