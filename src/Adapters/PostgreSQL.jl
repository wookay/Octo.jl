module PostgreSQL

export extract

include("sql_exports.jl")
include("sql_imports.jl") # DBMS Structured SubQuery _to_sql _placeholder _placeholders
using .Octo.Queryable: extract #
using .Octo: @sql_keywords, @sql_functions

const DatabaseID = DBMS.PostgreSQL

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

export         AUTOCOMMIT, COPY, CURRENT_DATE, DESCRIBE, EXPLAIN, FALSE, LATERAL, SEQUENCE, SERIAL, TRUE, WINDOW
@sql_keywords  AUTOCOMMIT  COPY  CURRENT_DATE  DESCRIBE  EXPLAIN  FALSE  LATERAL  SEQUENCE  SERIAL  TRUE  WINDOW

export         COALESCE, NOW
@sql_functions COALESCE  NOW

using .Octo.AdapterBase: FromItem, SqlPart, _sqlrepr
import .Octo.AdapterBase: sqlrepr
function sqlrepr(db::DatabaseID, clause::FromItem)::SqlPart
    _sqlrepr(db, clause; with_as=false)
end

end # Octo.Adapters.PostgreSQL
