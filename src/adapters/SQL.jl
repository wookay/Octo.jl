module SQL

include("sql_exports.jl")
include("sql_imports.jl") # Database Structured SubQuery _to_sql _placeholder _placeholders

const DatabaseID = Database.SQLDatabase

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

end # Octo.Adapters.SQL
