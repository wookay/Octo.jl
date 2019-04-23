module AdapterBase # Octo

using ..Octo
using .Octo.Queryable: Structured, FromItem, SubQuery
using .Octo: SQLElement, SQLAlias, SQLExtract, SQLFunctionName, SQLFunction, Field, Predicate, Raw, Enclosed, PlaceHolder, SQLKeyword, KeywordAllKeyword, VectorOfTuples
using .Octo.Schema
using .Octo.DBMS
using .Octo.DBMS: AbstractDatabase
using .Octo: Year, Month, Day, Hour, Minute, Second, CompoundPeriod, DatePeriod, TimePeriod, DateTime, format
using .Octo: @sql_keywords, @sql_functions, db_keywords, db_functionnames

const current = Dict{Symbol,AbstractDatabase}(
    :database => DBMS.SQL()
)

@sql_keywords  ADD ALL ALTER AND AS ASC BEGIN BETWEEN BY COMMIT COLUMN CONSTRAINT CREATE DATABASE DEFAULT DELETE DESC DISTINCT DROP EXCEPT EXECUTE EXISTS FOREIGN FROM FULL GROUP
@sql_keywords  HAVING IF IN INDEX INNER INSERT INTERSECT INTO IS JOIN KEY LEFT LIKE LIMIT NULL OFF OFFSET ON OR ORDER OUTER OVER
@sql_keywords  PARTITION PREPARE PRIMARY RECURSIVE REFERENCES RELEASE RIGHT ROLLBACK SAVEPOINT SELECT SET TABLE TO TRANSACTION TRIGGER UNION UPDATE USING VALUES WHERE WITH
# @sql_keywords ANY (Julia TypeVar)

# aggregates
@sql_functions AVG COUNT EVERY MAX MIN NOT SOME SUM

# rankings
@sql_functions DENSE_RANK RANK ROW_NUMBER


# Colored SQL statements
module Beautiful # Octo.AdapterBase

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

end # Octo.AdapterBase.Beautiful

const SqlPartElement = Beautiful.Element
const SqlPart        = Beautiful.Container
using .Beautiful: ElementStyle

const style_normal                  = ElementStyle(:normal)
const style_subquery_select         = ElementStyle(:light_green, true)
const style_subquery_non_select     = ElementStyle(:light_blue, true)
const style_placeholder             = ElementStyle(:green, true)
const style_keyword                 = ElementStyle(:cyan)
const style_functionname            = ElementStyle(:cyan)
const style_function                = ElementStyle(:yellow)
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
const style_vector_of_tuples        = ElementStyle(:yellow)

# sqlrepr -> SqlPartElement

sqlrepr(::DB where DB<:AbstractDatabase, sym::Symbol)::SqlPartElement        = SqlPartElement(style_normal, sym)
sqlrepr(::DB where DB<:AbstractDatabase, num::Number)::SqlPartElement        = SqlPartElement(style_normal, num)
sqlrepr(::DB where DB<:AbstractDatabase, f::Function)::SqlPartElement        = SqlPartElement(style_normal, f)
sqlrepr(::DB where DB<:AbstractDatabase, h::PlaceHolder)::SqlPartElement     = SqlPartElement(style_placeholder, h.body)
sqlrepr(::DB where DB<:AbstractDatabase, el::SQLKeyword)::SqlPartElement     = SqlPartElement(style_keyword, el.name)
sqlrepr(::DB where DB<:AbstractDatabase, var::TypeVar)::SqlPartElement       = SqlPartElement(style_keyword, string(var)) # ANY
sqlrepr(::DB where DB<:AbstractDatabase, f::SQLFunctionName)::SqlPartElement = SqlPartElement(style_functionname, f.name)
sqlrepr(::DB where DB<:AbstractDatabase, T::Type)::SqlPartElement            = SqlPartElement(style_table_name, _table_name_of(T))

function sqlrepr(::DB where DB<:AbstractDatabase, M::Type{PlaceHolder})::SqlPartElement
    SqlPartElement(style_placeholder, '?')
end

# sqlrepr -> SqlPart

function enclosed_part(style, body::SqlPart)::SqlPart
    SqlPart([
        SqlPartElement(style, '('),
        body,
        SqlPartElement(style, ')')], "")
end

function sqlrepr(::DB where DB<:AbstractDatabase, str::String)::SqlPart
    quot = SqlPartElement(style_string, "'")
    SqlPart([quot, SqlPartElement(style_string, str), quot], "")
end

function sqlrepr(::DB where DB<:AbstractDatabase, field::Field)::SqlPart
    if field.clause isa Nothing ||
       field.clause.__octo_alias isa Nothing
        SqlPart([SqlPartElement(style_normal, field.name)], "")
    else
        if field.clause isa SubQuery
            (style_field_alias, style_field_dot, style_field_name) = (style_field_subquery_alias, style_field_subquery_dot, style_field_subquery_name)
        else # FromItem
            (style_field_alias, style_field_dot, style_field_name) = (style_field_fromclause_alias, style_field_fromclause_dot, style_field_fromclause_name)
        end
        SqlPart([
            SqlPartElement(style_field_alias, field.clause.__octo_alias),
            SqlPartElement(style_field_dot, '.'),
            SqlPartElement(style_field_name, field.name)], "")
    end
end

function sqlrepr(::DB where DB<:AbstractDatabase, raw::Raw)::SqlPart
    lines = split(raw.string, '\n'; keepempty=true)
    parts = []
    for (line_idx, line) in enumerate(lines)
        words = split(line, ' '; keepempty=true)
        for (word_idx, word) in enumerate(words)
            chars = collect(word)
            if all(isuppercase, chars)
                if word in db_keywords
                    push!(parts, SqlPartElement(style_keyword, word))
                elseif word in db_functionnames
                    push!(parts, SqlPartElement(style_functionname, word))
                else
                    push!(parts, SqlPartElement(style_normal, word))
                end
            elseif all(x -> isuppercase(x) || x in ('(', ','), chars)
                if word[1:end-1] in db_keywords
                    push!(parts, SqlPartElement(style_keyword, word[1:end-1]))
                    push!(parts, SqlPartElement(style_normal, ","))
                elseif word[1:end-1] in db_functionnames
                    push!(parts, SqlPartElement(style_functionname, word[1:end-1]))
                    push!(parts, SqlPartElement(style_normal, ","))
                else
                    push!(parts, SqlPartElement(style_normal, word))
                end
            else
                push!(parts, SqlPartElement(style_normal, word))
            end
            word_idx != length(words) && push!(parts, SqlPartElement(style_normal, ' '))
        end
        line_idx != length(lines) && push!(parts, SqlPartElement(style_normal, '\n'))
    end
    SqlPart(parts, "")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, el::KeywordAllKeyword)::SqlPart
    els = [el.left, *, el.right]
    SqlPart(sqlrepr.(Ref(db), els), " ")
end

function both_isa((a,b), T::Type)::Bool
    a isa T && b isa T
end

function subquery_startswith_select(subquery::SubQuery)::Bool
    first(subquery.__octo_query) === SELECT
end

function _subquery_predicate_side(db::DB where DB<:AbstractDatabase, side)
    if side isa SubQuery && side.__octo_alias isa Symbol
        if subquery_startswith_select(side)
            sqlrepr(db, side)
        else
            SqlPartElement(style_subquery_non_select, side.__octo_alias)
        end
    else
        sqlrepr(db, side)
    end
end

function sqlrepr(db::DB where DB<:AbstractDatabase, pred::Predicate)::SqlPart
    if ==(pred.func, ==)
        op = :(=)
    else
        op = pred.func
    end
    (left, right) = _subquery_predicate_side.(Ref(db), (pred.left, pred.right))
    parts = [left, sqlrepr(db, op), right]
    body = SqlPart(parts, " ")
    if op in (+, -) && both_isa((pred.left, pred.right), Union{Field, SQLFunction})
        enclosed_part(style_predicate_enclosed, body)
    else
        body
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

function _sqlrepr(db::DB where DB<:AbstractDatabase, clause::FromItem; with_as::Bool)::SqlPart
    table_name = _table_name_of(clause.__octo_model)
    part = SqlPartElement(style_table_name, table_name)
    if clause.__octo_alias isa Nothing
        parts = [part]
    else
        if table_name == String(clause.__octo_alias)
            parts = [part]
        else
            parts = [part, (with_as ? [sqlrepr(db, AS)] : [])..., SqlPartElement(style_table_alias, clause.__octo_alias)]
        end
    end
    SqlPart(parts, " ")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, clause::FromItem)::SqlPart
    _sqlrepr(db, clause; with_as=true)
end

function sqlrepr(db::DB where DB<:AbstractDatabase, subquery::SubQuery)::SqlPart
    query = subquery.__octo_query
    body = SqlPart(vcat(sqlrepr.(Ref(db), query)...), " ")
    style = subquery_startswith_select(subquery) ? style_subquery_select : style_subquery_non_select
    part = enclosed_part(style, body)
    if subquery.__octo_alias isa Nothing
        part
    else
        SqlPart([
            part,
            sqlrepr(db, AS),
            SqlPartElement(style, subquery.__octo_alias),
        ], " ")
    end
end

function sqlrepr(db::DB where DB<:AbstractDatabase, tup::NamedTuple)::SqlPart
    els = map(kv -> Predicate(==, kv.first, kv.second), collect(pairs(tup)))
    SqlPart(sqlrepr.(Ref(db), els), ", ")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, enclosed::Enclosed)::SqlPart
    body = SqlPart(sqlrepr.(Ref(db), enclosed.values), ", ")
    enclosed_part(style_normal, body)
end

function sqlrepr(db::DB where DB<:AbstractDatabase, vec_of_tuples::VectorOfTuples)::SqlPart
    parts = map(x -> enclosed_part(style_vector_of_tuples, SqlPart(sqlrepr.(Ref(db), collect(x)), ", ")), vec_of_tuples.values)
    SqlPart(parts, ", ")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, a::SQLAlias)::SqlPart
    els = [a.field, AS, a.alias]
    SqlPart(sqlrepr.(Ref(db), els), " ")
end

@sql_keywords EXTRACT YEAR MONTH DAY HOUR MINUTE SECOND TIMESTAMP INTERVAL
function sqlrepr(db::DB where DB<:AbstractDatabase, extract::SQLExtract)::SqlPart
    body = SqlPart(sqlrepr.(Ref(db), [extract.field, FROM, extract.from]), " ")
    SqlPart([
        sqlrepr(db, EXTRACT),
        enclosed_part(style_normal, body)
    ], "")
end

sqlrepr(db::DB where DB<:AbstractDatabase, ::Type{Year})::SqlPartElement   = sqlrepr(db, YEAR)
sqlrepr(db::DB where DB<:AbstractDatabase, ::Type{Month})::SqlPartElement  = sqlrepr(db, MONTH)
sqlrepr(db::DB where DB<:AbstractDatabase, ::Type{Day})::SqlPartElement    = sqlrepr(db, DAY)
sqlrepr(db::DB where DB<:AbstractDatabase, ::Type{Hour})::SqlPartElement   = sqlrepr(db, HOUR)
sqlrepr(db::DB where DB<:AbstractDatabase, ::Type{Minute})::SqlPartElement = sqlrepr(db, MINUTE)
sqlrepr(db::DB where DB<:AbstractDatabase, ::Type{Second})::SqlPartElement = sqlrepr(db, SECOND)

function sqlrepr(db::DB where DB<:AbstractDatabase, dt::DateTime)::SqlPart
    str = format(dt, "yyyy-mm-dd HH:MM:SS")
    quot = SqlPartElement(style_dates, "'")
    SqlPart([
        sqlrepr(db, TIMESTAMP),
        SqlPart([quot, SqlPartElement(style_dates, str), quot], "")
    ], " ")
end

function compound_period_string(x::CompoundPeriod)
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

function sqlrepr(db::DB where DB<:AbstractDatabase, period::Union{DatePeriod, TimePeriod})::SqlPart
    str = string(period)
    quot = SqlPartElement(style_dates, "'")
    SqlPart([
        sqlrepr(db, INTERVAL),
        SqlPart([quot, SqlPartElement(style_dates, str), quot], "")
    ], " ")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, period::CompoundPeriod)::SqlPart
    str = compound_period_string(period)
    quot = SqlPartElement(style_dates, "'")
    SqlPart([
        sqlrepr(db, INTERVAL),
        SqlPart([quot, SqlPartElement(style_dates, str), quot], "")
    ], " ")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, f::SQLFunction)::SqlPart
    SqlPart([
        SqlPartElement(style_function, f.name),
        sqlrepr(db, Enclosed(collect(f.fields))),
        ], "")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, tup::Tuple)::SqlPart
    parts = []
    for el in tup
        push!(parts, sqlrepr(db, el))
    end
    SqlPart(parts, ", ")
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
        elseif el isa SubQuery
            if prev === AS
                push!(els, typeof(el)(el.__octo_query, nothing))
            elseif prev === JOIN
                push!(els, el.__octo_alias)
            else
                push!(els, el)
            end
        elseif el isa Tuple
            if prev === IN ||
               prev === OVER ||
               prev === USING
                push!(els, Enclosed(collect(el)))
            else
                push!(els, el)
            end
        elseif prev === USING
            push!(els, Enclosed([el]))
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
    printstyled(io, nameof(typeof(element)), color=:underline)
    print(io, ' ')
    printpart(io, sqlrepr(db, element))
end

function _show(io::IO, ::MIME"text/plain", db::DB where DB<:AbstractDatabase, query::Structured)
    if any(x -> x isa SQLElement, query)
        printpart(io, sqlrepr(db, query))
    else
        Base.show(io, query)
    end
end

end # module Octo.AdapterBase
