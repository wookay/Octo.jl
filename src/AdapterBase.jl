module AdapterBase # Octo

module Database
abstract type AbstractDatabase end
struct SQLDatabase <: AbstractDatabase end
struct SQLiteDatabase <: AbstractDatabase end
struct MySQLDatabase <: AbstractDatabase end
struct PostgreSQLDatabase <: AbstractDatabase end
struct JDBCDatabase <: AbstractDatabase end
end # module Octo.AdapterBase.Database

import ...Octo
import .Octo.Queryable: Structured, FromClause, SubQuery, OverClause, OverClauseError
import .Octo: Schema
import .Octo: SQLElement, SQLAlias, SQLFunction, Field, Predicate, Raw, Enclosed, PlaceHolder, Keyword, KeywordAllKeyword
import .Octo: @sql_keywords, @sql_functions
import .Database: AbstractDatabase

const current = Dict{Symbol,AbstractDatabase}(
    :database => Database.SQLDatabase()
)

"""
    Beuatiful

Colored SQL statements
"""
module Beuatiful # Octo.AdapterBase

struct ElementStyle
    color::Symbol
    bold::Bool
    ElementStyle(color::Symbol, bold::Bool=false) = new(color, bold)
end

struct Element
    style::ElementStyle
    body
end

struct Container
    elements::Vector{Union{Element,Container}}
    sep::String
end

end # Octo.AdapterBase.Beuatiful

const SqlPartElement = Beuatiful.Element
const SqlPart        = Beuatiful.Container
import .Beuatiful: ElementStyle

const style_normal                 = ElementStyle(:normal)
const style_subquery               = ElementStyle(:light_green, true)
const style_overclause             = ElementStyle(:light_blue, true)
const style_placeholders           = ElementStyle(:green, true)
const style_keywords               = ElementStyle(:cyan)
const style_functions              = ElementStyle(:yellow)
const style_string                 = ElementStyle(:light_magenta)
const style_table_name             = ElementStyle(:normal, false)
const style_table_alias            = ElementStyle(:normal, true)
const style_field_fromclause_alias = ElementStyle(:normal)
const style_field_fromclause_dot   = ElementStyle(:normal)
const style_field_fromclause_name  = ElementStyle(:normal)
const style_field_subquery_alias   = ElementStyle(:light_green)
const style_field_subquery_dot     = ElementStyle(:normal)
const style_field_subquery_name    = ElementStyle(:normal)
const style_field_overclause_alias = ElementStyle(:light_blue)
const style_field_overclause_dot   = ElementStyle(:normal)
const style_field_overclause_name  = ElementStyle(:normal)

# sqlrepr -> SqlPartElement

sqlrepr(::DB where DB<:AbstractDatabase, el::Keyword)::SqlPartElement = SqlPartElement(style_keywords, el.name)
sqlrepr(::DB where DB<:AbstractDatabase, sym::Symbol)::SqlPartElement = SqlPartElement(style_normal, sym)
sqlrepr(::DB where DB<:AbstractDatabase, num::Number)::SqlPartElement = SqlPartElement(style_normal, num)
sqlrepr(::DB where DB<:AbstractDatabase, f::Function)::SqlPartElement = SqlPartElement(style_normal, f)
sqlrepr(::DB where DB<:AbstractDatabase, h::PlaceHolder)::SqlPartElement = SqlPartElement(style_placeholders, h.body)
sqlrepr(::DB where DB<:AbstractDatabase, raw::Raw)::SqlPartElement = SqlPartElement(style_normal, raw.string)

function sqlrepr(::DB where DB<:AbstractDatabase, M::Type{PlaceHolder})::SqlPartElement
    SqlPartElement(style_placeholders, '?')
end

# sqlrepr -> SqlPart

function sqlrepr(::DB where DB<:AbstractDatabase, str::String)::SqlPart
    quot = SqlPartElement(style_string, "'")
    SqlPart([quot, SqlPartElement(style_string, str), quot], "")
end

function sqlrepr(::DB where DB<:AbstractDatabase, field::Field)::SqlPart
    if field.clause.__octo_as isa Nothing
        SqlPart([SqlPartElement(style_normal, field.name)], "")
    else
        if field.clause isa SubQuery
            (style_field_alias, style_field_dot, style_field_name) = (style_field_subquery_alias, style_field_subquery_dot, style_field_subquery_name)
        elseif field.clause isa OverClause
            (style_field_alias, style_field_dot, style_field_name) = (style_field_overclause_alias, style_field_overclause_dot, style_field_overclause_name)
        else # FromClause
            (style_field_alias, style_field_dot, style_field_name) = (style_field_fromclause_alias, style_field_fromclause_dot, style_field_fromclause_name)
        end
        SqlPart([
            SqlPartElement(style_field_alias, field.clause.__octo_as),
            SqlPartElement(style_field_dot, '.'),
            SqlPartElement(style_field_name, field.name)], "")
    end
end

function sqlrepr(db::DB where DB<:AbstractDatabase, el::KeywordAllKeyword)::SqlPart
    els = [el.left, *, el.right]
    SqlPart(sqlrepr.(Ref(db), els), " ")
end

function _over_clause_predicate_side(db::DB where DB<:AbstractDatabase, side)
    if side isa OverClause && side.__octo_as isa Symbol
        SqlPartElement(style_overclause, side.__octo_as)
    else
        sqlrepr(db, side)
    end
end

function sqlrepr(db::DB where DB<:AbstractDatabase, pred::Predicate)::SqlPart
    left  = _over_clause_predicate_side(db, pred.left)
    right = _over_clause_predicate_side(db, pred.right)
    if ==(pred.func, ==)
        op = :(=)
    else
        op = pred.func
    end
    parts = [left, sqlrepr(db, op), right]
    SqlPart(parts, " ")
end

function _table_name_of(M::Type)::String # throw Schema.TableNameError
    Tname = Base.typename(M)
    if haskey(Schema.tables, Tname)
        table = Schema.tables[Tname]
        table[:table_name]
    else
        name = nameof(M)
        throw(Schema.TableNameError("""Provide schema table_name by `Schema.model($name, table_name="tbl")`"""))
    end
end

function _sqlrepr(db::DB where DB<:AbstractDatabase, clause::FromClause; with_as::Bool)::SqlPart
    table_name = _table_name_of(clause.__octo_model)
    part = SqlPartElement(style_table_name, table_name)
    if clause.__octo_as isa Nothing
        parts = [part]
    else
        if table_name == String(clause.__octo_as)
            parts = [part]
        else
            parts = [part, (with_as ? [sqlrepr(db, AS)] : [])..., SqlPartElement(style_table_alias, clause.__octo_as)]
        end
    end
    SqlPart(parts, " ")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, clause::FromClause)::SqlPart
    _sqlrepr(db, clause; with_as=true)
end

function sqlrepr(db::DB where DB<:AbstractDatabase, subquery::SubQuery)::SqlPart
    query = subquery.__octo_query
    body = SqlPart(vcat(sqlrepr.(Ref(db), query)...), " ")
    part = SqlPart([
        SqlPartElement(style_subquery, '('),
        body,
        SqlPartElement(style_subquery, ')')], "")
    if subquery.__octo_as isa Nothing
        part
    else
        SqlPart([
            part,
            sqlrepr(db, AS),
            SqlPartElement(style_subquery, subquery.__octo_as),
        ], " ")
    end
end

function sqlrepr(db::DB where DB<:AbstractDatabase, clause::OverClause)::SqlPart # throw OverClauseError
    if length(clause.__octo_query) >= 3 && clause.__octo_query[2] isa Keyword && clause.__octo_query[2].name == :OVER
        bodypart = SqlPart([
            SqlPartElement(style_overclause, '('),
            SqlPart(sqlrepr.(Ref(db), clause.__octo_query[3:end]), " "),
            SqlPartElement(style_overclause, ')')], "")
        part = SqlPart([
            sqlrepr(db, clause.__octo_query[1]),
            sqlrepr(db, OVER),
            bodypart
        ], " ")
        if clause.__octo_as isa Nothing
             part
        else
            SqlPart([
                part,
                sqlrepr(db, AS),
                SqlPartElement(style_overclause, clause.__octo_as),
            ], " ")
        end
    else
        throw(OverClauseError("OVER clause error"))
    end
end

function sqlrepr(db::DB where DB<:AbstractDatabase, tup::Tuple)::SqlPart
    els = collect(tup)
    SqlPart(sqlrepr.(Ref(db), els), ", ")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, tup::NamedTuple)::SqlPart
    els = map(kv -> Predicate(==, kv.first, kv.second), collect(pairs(tup)))
    SqlPart(sqlrepr.(Ref(db), els), ", ")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, enclosed::Enclosed)::SqlPart
    els = [enclosed.values...]
    part = SqlPart(sqlrepr.(Ref(db), els), ", ")
    if enclosed.values isa Vector{PlaceHolder}
        length(enclosed.values) == 1 && return part
    end
    return SqlPart([
        SqlPartElement(style_normal, '('),
        part,
        SqlPartElement(style_normal, ')')], "")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, a::SQLAlias)::SqlPart
    els = [a.field, AS, a.alias]
    SqlPart(sqlrepr.(Ref(db), els), " ")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, f::SQLFunction)::SqlPart
    SqlPart([
        SqlPartElement(style_functions, f.name),
        SqlPartElement(style_normal, '('),
        sqlrepr.(Ref(db), f.fields)...,
        SqlPartElement(style_normal, ')')], "")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, query::Structured)::SqlPart
    nth = 1
    els = []
    prev = nothing
    for el in query
        if el isa Type{PlaceHolder}
            push!(els, _placeholder(db, nth))
            nth += 1
        elseif el isa Predicate && el.right isa Type{PlaceHolder}
            push!(els, Predicate(el.func, el.left, _placeholder(db, nth)))
            nth += 1
        elseif el isa Tuple && prev === IN
            push!(els, Enclosed(collect(el)))
        else
            push!(els, el)
        end
        prev = el
    end
    SqlPart(sqlrepr.(Ref(db), els), " ")
end

function joinpart(part::SqlPart)::String
    join(map(part.elements) do el
        if el isa SqlPart
            joinpart(el)
        elseif el isa SqlPartElement
            el.body
        end
    end, part.sep)
end

function printpart(io::IO, part::SqlPart)
    for (idx, el) in enumerate(part.elements)
        if el isa SqlPart
            printpart(io, el)
        elseif el isa SqlPartElement
            printstyled(io, el.body; color=el.style.color, bold=el.style.bold)
        end
        length(part.elements) == idx || print(io, part.sep)
    end
end

# _to_sql

function _to_sql(db::DB where DB<:AbstractDatabase, element::Union{E,Structured} where E<:SQLElement)::String
    joinpart(sqlrepr(db, element))
end

# _placeholder, _placeholders

function _placeholder(db::DB where DB<:AbstractDatabase, nth::Int)
    PlaceHolder("?")
end

function _placeholders(db::DB where DB<:AbstractDatabase, dims::Int)
    Enclosed(fill(_placeholder(db, 1), dims))
end

# _show

function Base.show(io::IO, mime::MIME"text/plain", element::Union{E,Structured} where E<:SQLElement)
    db = current[:database]    # to be changed by Repo.connect
    _show(io, mime, db, element)
end

function _show(io::IO, ::MIME"text/plain", db::DB where DB<:AbstractDatabase, element::E where E<:SQLElement)
    printpart(io, sqlrepr(db, element))
end

function _show(io::IO, ::MIME"text/plain", db::DB where DB<:AbstractDatabase, query::Structured)
    if any(x -> x isa SQLElement, query)
        printpart(io, sqlrepr(db, query))
    else
        Base.show(io, query)
    end
end


@sql_keywords  AND AS ASC BETWEEN BY CREATE DATABASE DELETE DESC DISTINCT DROP EXISTS FROM FULL GROUP
@sql_keywords  HAVING IF IN INNER INSERT INTO IS JOIN LEFT LIKE LIMIT NOT NULL OFFSET ON OR ORDER OUTER OVER
@sql_keywords  PARTITION RIGHT SELECT SET TABLE UPDATE USING VALUES WHERE

# aggregates
@sql_functions AVG COUNT MAX MIN SUM

# rankings
@sql_functions DENSE_RANK RANK ROW_NUMBER

end # module Octo.AdapterBase
