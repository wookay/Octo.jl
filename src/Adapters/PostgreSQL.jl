module PostgreSQL

include("sql_exports.jl")
include("sql_imports.jl") # Database Structured SubQuery OverClause _to_sql _placeholder _placeholders
import .Octo.Queryable: window #
import .Octo: @keywords

const DatabaseID = Database.PostgreSQLDatabase

"""
    to_sql(query::Structured)::String
"""
to_sql(query::Structured)::String = _to_sql(DatabaseID(), query)

"""
    to_sql(subquery::SubQuery)::String
"""
to_sql(subquery::SubQuery)::String = _to_sql(DatabaseID(), subquery)

"""
    to_sql(clause::OverClause)::String
"""
to_sql(clause::OverClause)::String = _to_sql(DatabaseID(), clause)

placeholder(nth::Int) = _placeholder(DatabaseID(), nth)
placeholders(dims::Int) = _placeholders(DatabaseID(), dims)

_placeholder(db::DatabaseID, nth::Int) = PlaceHolder("\$$nth")
_placeholders(db::DatabaseID, dims::Int) = Enclosed([PlaceHolder("\$$x") for x in 1:dims])

import .Octo.AdapterBase: FromClause, SqlPart, sqlrepr
function sqlrepr(db::DatabaseID, clause::FromClause)::SqlPart
    els = [clause.__octo_model]
    if clause.__octo_as isa Nothing
    else
        Tname = Base.typename(clause.__octo_model)
        if haskey(Schema.tables, Tname) && String(clause.__octo_as) == Schema.tables[Tname][:table_name]
        else
            els = [clause.__octo_model, clause.__octo_as]
        end
    end
    SqlPart(sqlrepr.(Ref(db), els), " ")
end

export    FALSE, LATERAL, TRUE, WITH
@keywords FALSE  LATERAL  TRUE  WITH

end # Octo.Adapters.PostgreSQL
