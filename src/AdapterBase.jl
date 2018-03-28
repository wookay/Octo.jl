module AdapterBase # Octo

module Database
abstract type AbstractDatabase end
struct SQLDatabase <: AbstractDatabase end
struct SQLiteDatabase <: AbstractDatabase end
struct MySQLDatabase <: AbstractDatabase end
struct PostgreSQLDatabase <: AbstractDatabase end
struct JDBCDatabase <: AbstractDatabase end
end # module Octo.AdapterBase.Database

import ...Schema
import ...Queryable: Structured, FromClause, SubQuery, OverClause, OverClauseError
import ...Octo: SQLElement, Field, SQLAlias, Predicate, Raw, Enclosed, PlaceHolder, Keyword, KeywordAllKeyword
import ...Octo: AggregateFunction, RankingFunction
import ...Octo: @keywords, @aggregates, @rankings
import .Database: AbstractDatabase

const current = Dict{Symbol,AbstractDatabase}(
    :database => Database.SQLDatabase()
)

struct ElementStyle
    color::Symbol
    bold::Bool
    ElementStyle(color::Symbol, bold::Bool=false) = new(color, bold)
end

struct SqlPartElement
    style::ElementStyle
    body
end

struct SqlPart
    elements::Vector{Union{SqlPartElement,SqlPart}}
    sep::String
end

const style_normal       = ElementStyle(:normal)
const style_subquery     = ElementStyle(:light_green, true)
const style_overclause   = ElementStyle(:light_blue, true)
const style_placeholders = ElementStyle(:green, true)
const style_keyword      = ElementStyle(:cyan)
const style_string       = ElementStyle(:light_magenta)
const style_functions    = ElementStyle(:yellow)

# sqlrepr -> SqlPartElement

sqlrepr(::DB where DB<:AbstractDatabase, el::Keyword)::SqlPartElement = SqlPartElement(style_keyword, el.name)
sqlrepr(::DB where DB<:AbstractDatabase, sym::Symbol)::SqlPartElement = SqlPartElement(style_normal, sym)
sqlrepr(::DB where DB<:AbstractDatabase, num::Number)::SqlPartElement = SqlPartElement(style_normal, num)
sqlrepr(::DB where DB<:AbstractDatabase, f::Function)::SqlPartElement = SqlPartElement(style_normal, f)
sqlrepr(::DB where DB<:AbstractDatabase, h::PlaceHolder)::SqlPartElement = SqlPartElement(style_placeholders, h.body)
sqlrepr(::DB where DB<:AbstractDatabase, raw::Raw)::SqlPartElement = SqlPartElement(style_normal, raw.string)

function sqlrepr(::DB where DB<:AbstractDatabase, M::Type{PlaceHolder})::SqlPartElement
    SqlPartElement(style_placeholders, '?')
end

# sqlrepr -> SqlPart

function sqlrepr(::DB where DB<:AbstractDatabase, M::Type)::SqlPart # throw Schema.TableNameError
    Tname = Base.typename(M)
    if haskey(Schema.tables, Tname)
        table = Schema.tables[Tname]
        el = SqlPartElement(style_normal, table[:table_name])
        SqlPart([el], "")
    else
        name = nameof(M)
        throw(Schema.TableNameError("""Provide schema table_name by `Schema.model($name, table_name="tbl")`"""))
    end
end

function sqlrepr(::DB where DB<:AbstractDatabase, str::String)::SqlPart
    quot = SqlPartElement(style_string, "'")
    SqlPart([quot, SqlPartElement(style_string, str), quot], "")
end

function sqlrepr(::DB where DB<:AbstractDatabase, field::Field)::SqlPart
    if field.clause.__octo_as isa Nothing
        SqlPart([SqlPartElement(style_normal, field.name)], "")
    else
        SqlPart([
            SqlPartElement(style_normal, field.clause.__octo_as),
            SqlPartElement(style_normal, '.'),
            SqlPartElement(style_normal, field.name)], "")
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

function sqlrepr(db::DB where DB<:AbstractDatabase, clause::FromClause)::SqlPart
    if clause.__octo_as isa Nothing
        els = [clause.__octo_model]
    else
        els = [clause.__octo_model, AS, clause.__octo_as]
    end
    SqlPart(sqlrepr.(Ref(db), els), " ")
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

function sqlrepr(db::DB where DB<:AbstractDatabase, f::AggregateFunction)::SqlPart
    SqlPart([
        SqlPartElement(style_functions, f.name),
        SqlPartElement(style_normal, '('),
        sqlrepr(db, f.field),
        SqlPartElement(style_normal, ')')], "")
end

function sqlrepr(db::DB where DB<:AbstractDatabase, f::RankingFunction)::SqlPart
    SqlPart([
        SqlPartElement(style_functions, f.name),
        SqlPartElement(style_normal, '('),
        SqlPartElement(style_normal, ')')], "")
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

function _to_sql(db::DB where DB<:AbstractDatabase, query::Structured)::String
    nth = 1
    els = []
    for el in query
        if el isa Type{PlaceHolder}
            push!(els, _placeholder(db, nth))
            nth += 1
        elseif el isa Predicate && el.right isa Type{PlaceHolder}
            push!(els, Predicate(el.func, el.left, _placeholder(db, nth)))
            nth += 1
        else
            push!(els, el)
        end
    end
    part = SqlPart(sqlrepr.(Ref(db), els), " ")
    joinpart(part)
end

function _to_sql(db::DB where DB<:AbstractDatabase, subquery::SubQuery)::String
    joinpart(sqlrepr(db, subquery))
end

function _to_sql(db::DB where DB<:AbstractDatabase, clause::OverClause)::String
    joinpart(sqlrepr(db, clause))
end

# _placeholder, _placeholders

function _placeholder(db::DB where DB<:AbstractDatabase, nth::Int)
    PlaceHolder("?")
end

function _placeholders(db::DB where DB<:AbstractDatabase, dims::Int)
    Enclosed(fill(_placeholder(db, 1), dims))
end

# _show

function Base.show(io::IO, mime::MIME"text/plain", query::Structured)
    db = current[:database]    # to be changed by Repo.connect
    _show(io, mime, db, query)
end

function _show(io::IO, ::MIME"text/plain", db::DB where DB<:AbstractDatabase, query::Structured)
    if any(x -> x isa SQLElement, query)
        els = vcat(query...)
        part = SqlPart(sqlrepr.(Ref(db), els), " ")
        printpart(io, part)
    else
        Base.show(io, query)
    end
end


@keywords AND AS ASC BETWEEN BY CREATE DATABASE DELETE DESC DISTINCT DROP EXISTS FROM FULL GROUP
@keywords HAVING IF INNER INSERT INTO IS JOIN LEFT LIKE LIMIT NOT NULL OFFSET ON OR ORDER OUTER OVER
@keywords PARTITION RIGHT SELECT SET TABLE UPDATE USING VALUES WHERE

@aggregates AVG COUNT MAX MIN SUM

@rankings DENSE_RANK RANK ROW_NUMBER

end # module Octo.AdapterBase
