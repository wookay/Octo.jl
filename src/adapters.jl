module Adapters

module Database
const Default = Any
struct SQLite end
end # module Octo.Adapters.Database

include("adapters/sql.jl")
include("adapters/sqlite.jl")

end # module Octo.Adapters
