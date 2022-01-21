module DuckDB

include("sql_exports.jl")
include("sql_imports.jl") # DBMS Structured SubQuery _to_sql _placeholder _placeholders
using .Octo: @sql_keywords, @sql_functions

const DatabaseID = DBMS.DuckDB

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

_placeholder(db::DatabaseID, nth::Int) = PlaceHolder("\$$nth")
_placeholders(db::DatabaseID, dims::Int) = Enclosed([PlaceHolder("\$$x") for x in 1:dims])

end # Octo.Adapters.DuckDB
