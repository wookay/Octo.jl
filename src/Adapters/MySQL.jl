module MySQL

include("sql_exports.jl")
include("sql_imports.jl") # DBMS Structured SubQuery _to_sql _placeholder _placeholders
using .Octo: @sql_keywords

const DatabaseID = DBMS.MySQL

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

export        AUTO_INCREMENT, DESCRIBE
@sql_keywords AUTO_INCREMENT  DESCRIBE

end # Octo.Adapters.MySQL
