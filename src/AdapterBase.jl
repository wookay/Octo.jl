module AdapterBase # Octo

module Database
abstract type AbstractDatabase end
struct SQLDatabase <: AbstractDatabase end
struct SQLiteDatabase <: AbstractDatabase end
struct MySQLDatabase <: AbstractDatabase end
struct PostgreSQLDatabase <: AbstractDatabase end
struct JDBCDatabase <: AbstractDatabase end
end # module Octo.AdapterBase.Database

import .Database: AbstractDatabase
import ..Octo
import .Octo.Queryable: Structured, FromClause, SubQuery, WindowFrame
import .Octo: SQLElement, SQLAlias, SQLOver, SQLExtract, SQLFunction, Field, Predicate, Raw, Enclosed, PlaceHolder, Keyword, KeywordAllKeyword
import .Octo: Schema
import .Octo: @sql_keywords, @sql_functions
import ..Deps: Dates

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

const style_normal                  = ElementStyle(:normal)
const style_subquery                = ElementStyle(:light_green, true)
const style_windowframe             = ElementStyle(:light_blue, true)
const style_placeholders            = ElementStyle(:green, true)
const style_keywords                = ElementStyle(:cyan)
const style_functions               = ElementStyle(:yellow)
const style_string                  = ElementStyle(:light_magenta)
const style_dates                   = ElementStyle(:light_green)
const style_predicate_enclosed      = ElementStyle(:normal)
const style_table_name              = ElementStyle(:normal, false)
const style_table_alias             = ElementStyle(:normal, true)
const style_field_fromclause_alias  = ElementStyle(:normal)
const style_field_fromclause_dot    = ElementStyle(:normal)
const style_field_fromclause_name   = ElementStyle(:normal)
const style_field_subquery_alias    = ElementStyle(:light_green)
const style_field_subquery_dot      = ElementStyle(:normal)
const style_field_subquery_name     = ElementStyle(:normal)
const style_field_windowframe_alias = ElementStyle(:light_blue)
const style_field_windowframe_dot   = ElementStyle(:normal)
const style_field_windowframe_name  = ElementStyle(:normal)

# sqlrepr -> SqlPartElement

sqlrepr(::DB where DB<:AbstractDatabase, el::Keyword)::SqlPartElement    = SqlPartElement(style_keywords, el.name)
sqlrepr(::DB where DB<:AbstractDatabase, sym::Symbol)::SqlPartElement    = SqlPartElement(style_normal, sym)
sqlrepr(::DB where DB<:AbstractDatabase, num::Number)::SqlPartElement    = SqlPartElement(style_normal, num)
sqlrepr(::DB where DB<:AbstractDatabase, f::Function)::SqlPartElement    = SqlPartElement(style_normal, f)
sqlrepr(::DB where DB<:AbstractDatabase, h::PlaceHolder)::SqlPartElement = SqlPartElement(style_placeholders, h.body)
sqlrepr(::DB where DB<:AbstractDatabase, raw::Raw)::SqlPartElement       = SqlPartElement(style_normal, raw.string)

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
        elseif field.clause isa WindowFrame
            (style_field_alias, style_field_dot, style_field_name) = (style_field_windowframe_alias, style_field_windowframe_dot, style_field_windowframe_name)
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

function _window_frame_predicate_side(db::DB where DB<:AbstractDatabase, side)
    if side isa WindowFrame && side.__octo_as isa Symbol
        SqlPartElement(style_windowframe, side.__octo_as)
    else
        sqlrepr(db, side)
    end
end

function both_isa((a,b), T::Type)::Bool
    a isa T && b isa T
end

function sqlrepr(db::DB where DB<:AbstractDatabase, pred::Predicate)::SqlPart
    if ==(pred.func, ==)
        op = :(=)
    else
        op = pred.func
    end
    (left, right) = _window_frame_predicate_side.(Ref(db), (pred.left, pred.right))
    parts = [left, sqlrepr(db, op), right]
    predpart = SqlPart(parts, " ")
    if op in (+, -) && both_isa((pred.left, pred.right), Union{Field, SQLFunction})
        enclosed = [
            SqlPartElement(style_predicate_enclosed, '('),
            predpart,
            SqlPartElement(style_predicate_enclosed, ')')]
        SqlPart(enclosed, "")
    else
        predpart
    end
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

function sqlrepr(db::DB where DB<:AbstractDatabase, frame::WindowFrame)::SqlPart
    query = frame.__octo_query
    body = SqlPart(vcat(sqlrepr.(Ref(db), query)...), " ")
    part = SqlPart([
        SqlPartElement(style_windowframe, '('),
        body,
        SqlPartElement(style_windowframe, ')')], "")
    if frame.__octo_as isa Nothing
         part
    else
        SqlPart([
            part,
            sqlrepr(db, AS),
            SqlPartElement(style_windowframe, frame.__octo_as),
        ], " ")
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
    SqlPart([
        SqlPartElement(style_normal, '('),
        part,
        SqlPartElement(style_normal, ')')], "")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, a::SQLAlias)::SqlPart
    els = [a.field, AS, a.alias]
    SqlPart(sqlrepr.(Ref(db), els), " ")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, o::SQLOver)::SqlPart
    if o.query isa WindowFrame
        els = [o.field, OVER, o.query]
        SqlPart(sqlrepr.(Ref(db), els), " ")
    else # Vector
        part = SqlPart(sqlrepr.(Ref(db), o.query), " ")
        enclosed = SqlPart([
            SqlPartElement(style_normal, '('),
            part,
            SqlPartElement(style_normal, ')')], "")
        SqlPart([
            sqlrepr.(Ref(db), [o.field, OVER])...,
            enclosed,
        ], " ")
    end
end

@sql_keywords EXTRACT MONTH TIMESTAMP INTERVAL
function sqlrepr(db::DB where DB<:AbstractDatabase, extract::SQLExtract)::SqlPart
    part = SqlPart(sqlrepr.(Ref(db), [extract.field, FROM, extract.from]), " ")
    SqlPart([
        sqlrepr(db, EXTRACT),
        SqlPartElement(style_normal, '('),
        part,
        SqlPartElement(style_normal, ')')], "")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, month::Type{Dates.Month})::SqlPartElement
    sqlrepr(db, MONTH)
end

function sqlrepr(db::DB where DB<:AbstractDatabase, dt::Dates.DateTime)::SqlPart
    str = Dates.format(dt, "yyyy-mm-dd HH:MM:SS")
    quot = SqlPartElement(style_dates, "'")
    SqlPart([
        sqlrepr(db, TIMESTAMP),
        SqlPart([quot, SqlPartElement(style_dates, str), quot], "")
    ], " ")
end

function compound_period_string(x::Dates.CompoundPeriod)
    if isempty(x.periods)
        return "empty period"
    else
        s = ""
        for p in x.periods
            s *= string(' ', p)
        end
        return s[2:end]
    end
end

function sqlrepr(db::DB where DB<:AbstractDatabase, period::Union{Dates.DatePeriod, Dates.TimePeriod})::SqlPart
    str = string(period)
    quot = SqlPartElement(style_dates, "'")
    SqlPart([
        sqlrepr(db, INTERVAL),
        SqlPart([quot, SqlPartElement(style_dates, str), quot], "")
    ], " ")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, period::Dates.CompoundPeriod)::SqlPart
    str = compound_period_string(period)
    quot = SqlPartElement(style_dates, "'")
    SqlPart([
        sqlrepr(db, INTERVAL),
        SqlPart([quot, SqlPartElement(style_dates, str), quot], "")
    ], " ")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, f::SQLFunction)::SqlPart
    SqlPart([
        SqlPartElement(style_functions, f.name),
        sqlrepr(db, Enclosed(collect(f.fields))),
        ], "")
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
        elseif el isa WindowFrame
            if prev === AS
                push!(els, WindowFrame(el.__octo_query, nothing))
            else
                push!(els, el)
            end
        elseif el isa Tuple
            if prev === IN ||
               prev === OVER
                push!(els, Enclosed(collect(el)))
            else
                push!(els, el)
            end
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

function printpart(io::IO, el::SqlPartElement)
    printstyled(io, el.body; color=el.style.color, bold=el.style.bold)
end

function printpart(io::IO, part::SqlPart)
    for (idx, el) in enumerate(part.elements)
        printpart(io, el)
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
    if element isa Keyword ||
       element isa SQLFunction
        print(io, nameof(typeof(element)), ' ')
    end
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
