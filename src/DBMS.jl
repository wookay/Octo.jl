module DBMS # Octo

abstract type AbstractDatabase end

struct SQL <: AbstractDatabase end
struct SQLite <: AbstractDatabase end
struct MySQL <: AbstractDatabase end
struct PostgreSQL <: AbstractDatabase end
struct Hive <: AbstractDatabase end

end # module Octo.DBMS
