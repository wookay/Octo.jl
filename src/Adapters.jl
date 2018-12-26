module Adapters # Octo

include(joinpath("Adapters", "SQLite.jl"))
include(joinpath("Adapters", "MySQL.jl"))
include(joinpath("Adapters", "PostgreSQL.jl"))
include(joinpath("Adapters", "SQL.jl"))
include(joinpath("Adapters", "ODBC.jl"))
include(joinpath("Adapters", "JDBC.jl"))
include(joinpath("Adapters", "Hive.jl"))

end # module Octo.Adapters
