module Adapters

module Database
const Default = Any
struct SQLite end
struct MySQL end
end # module Octo.Adapters.Database

include("adapters/sql.jl")
include("adapters/sqlite.jl")
include("adapters/mysql.jl")

end # module Octo.Adapters
