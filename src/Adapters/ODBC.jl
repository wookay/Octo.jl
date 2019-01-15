module ODBC

include("sql_exports.jl")
include("sql_imports.jl") # DBMS Structured SubQuery _to_sql _placeholders

Database = Dict{Symbol,Type{D} where {D <: DBMS.AbstractDatabase}}(
    :ID => DBMS.SQL
)
DatabaseID() = Database[:ID]()

"""
    to_sql(query::Structured)::String
"""
to_sql(query::Structured)::String = _to_sql(DatabaseID(), query)

"""
    to_sql(subquery::SubQuery)::String
"""
to_sql(subquery::SubQuery)::String = _to_sql(DatabaseID(), subquery)

placeholder(nth::Int) = _placeholder(DatabaseID(), nth)
placeholders(dims::Int) = _placeholders(DatabaseID(), dims)

end # Octo.Adapters.ODBC
