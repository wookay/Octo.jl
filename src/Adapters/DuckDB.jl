module DuckDB

export read_csv

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


# support read_csv

using .Octo: SQLFunction
function read_csv(path_or_buffer; kwargs...)::SQLFunction
    SQLFunction(:read_csv, (path_or_buffer,), kwargs)
end

using .Octo.AdapterBase: SqlPart, SqlPartElement, style_functionname, style_normal
using .Octo.AdapterBase: AbstractDatabase
import .Octo.AdapterBase: sqlrepr

function sqlrepr(db::DBMS.DuckDB, tup::Tuple{Vararg{Pair{String, String}}})::SqlPart
    els = map(collect(tup)) do kv
            SqlPart([
                sqlrepr(db, kv.first),
                SqlPartElement(style_normal, ": "),
                sqlrepr(db, kv.second),
            ], "")
        end
    SqlPart([
        SqlPartElement(style_normal, "{"),
        SqlPart(els, ", "),
        SqlPartElement(style_normal, "}"),
    ], "")
end

function sqlrepr(db::DBMS.DuckDB, v::Vector{String})::SqlPart
    els = sqlrepr.(Ref(db), v)
    SqlPart([
        SqlPartElement(style_normal, "["),
        SqlPart(els, ", "),
        SqlPartElement(style_normal, "]"),
    ], "")
end

function sqlrepr(db::DBMS.DuckDB, p::Pair{Symbol, <:Any})::SqlPart
    SqlPart([
       sqlrepr(db, p.first),
       SqlPartElement(style_normal, " = "),
       sqlrepr(db, p.second),
    ], "")
end

function sqlfunc_signature_part(db::DB where DB<:AbstractDatabase, f::SQLFunction)::SqlPart
    if isempty(f.kwargs)
        kwargs_part = SqlPart([], "")
    else
        elements = sqlrepr.(Ref(db), collect(f.kwargs))
        if isempty(f.args)
            kwargs_part = SqlPart(elements, "")
        else
            kwargs_part = SqlPart([
                SqlPartElement(style_normal, ", "),
                SqlPart(elements, ", "),
            ] , "")
        end
    end
    SqlPart([
        SqlPartElement(style_functionname, f.name),
        SqlPartElement(style_normal, '('),
        sqlrepr(db, f.args),
        kwargs_part,
        SqlPartElement(style_normal, ')')
    ], "")
end

function sqlrepr(db::DBMS.DuckDB, f::SQLFunction)::SqlPart
    sqlfunc_signature_part(db, f)
end

end # Octo.Adapters.DuckDB
