module Adapters

module Database
const Default = Any
struct SQLite end
struct MySQL end
struct PostgreSQL end
end # module Octo.Adapters.Database

include("adapters/SQL.jl")
include("adapters/SQLite.jl")
include("adapters/MySQL.jl")
include("adapters/PostgreSQL.jl")

end # module Octo.Adapters
