module AdapterBase # Octo

module Database
abstract type AbstractDatabase end
const Default = Any
struct SQLDatabase <: AbstractDatabase end
struct SQLiteDatabase <: AbstractDatabase end
struct MySQLDatabase <: AbstractDatabase end
struct PostgreSQLDatabase <: AbstractDatabase end
struct JDBCDatabase <: AbstractDatabase end
end # module Octo.AdapterBase.Database

import ...Schema
import ...Queryable: Structured, FromClause, SubQuery, OverClause
import ...Octo: SQLElement, Field, SQLAlias, Predicate, Raw, Enclosed, PlaceHolder, Keyword, KeywordAllKeyword
import ...Octo: AggregateFunction, RankingFunction
import ...Octo: @keywords, @aggregates, @rankings

const current = Dict{Symbol, Database.AbstractDatabase}(
    :database => Database.SQLDatabase()
)

struct SqlPartElement
    color::Union{Symbol, Int}
    body
end

struct SqlPart
    elements::Vector{Union{SqlPart, SqlPartElement}}
    sep::String
end

# sqlpart
function sqlpart(element::SqlPartElement)::SqlPart
    SqlPart([element], "")
end

function sqlpart(elements::Vector, sep::String)::SqlPart
    SqlPart(elements, sep)
end

# sqlrepr - SqlPartElement

sqlrepr(::Database.Default, el::Keyword)::SqlPartElement = SqlPartElement(:cyan, el.name)
sqlrepr(::Database.Default, sym::Symbol)::SqlPartElement = SqlPartElement(:normal, sym)
sqlrepr(::Database.Default, num::Number)::SqlPartElement = SqlPartElement(:normal, num)
sqlrepr(::Database.Default, f::Function)::SqlPartElement = SqlPartElement(:normal, f)
sqlrepr(::Database.Default, h::PlaceHolder)::SqlPartElement = SqlPartElement(:yellow, h.body)
sqlrepr(::Database.Default, raw::Raw)::SqlPartElement = SqlPartElement(:normal, raw.string)

function sqlrepr(::Database.Default, M::Type{PlaceHolder})::SqlPartElement
    SqlPartElement(:yellow, '?')
end

function sqlrepr(::Database.Default, M::Type)::SqlPartElement
    Tname = Base.typename(M)
    if haskey(Schema.tables, Tname)
        info = Schema.tables[Tname]
        SqlPartElement(:normal, info[:table_name])
    else
        name = nameof(M)
        throw(Schema.TableNameError("""Provide schema table_name by `Schema.model($name, table_name="tbl")`"""))
    end
end

function sqlrepr(::Database.Default, str::String)::SqlPart
    quot = SqlPartElement(:light_magenta, "'")
    sqlpart([quot, SqlPartElement(:light_magenta, str), quot], "")
end

function sqlrepr(::Database.Default, field::Field)::SqlPart
    if field.clause.__octo_as isa Nothing
        sqlpart(SqlPartElement(:normal, field.name))
    else
        sqlpart([
            SqlPartElement(:normal, field.clause.__octo_as),
            SqlPartElement(:normal, '.'),
            SqlPartElement(:normal, field.name)], "")
    end
end

# sqlrepr - SqlPart

function sqlrepr(def::Database.Default, el::KeywordAllKeyword)::SqlPart
    sqlpart(sqlrepr.(Ref(def), [el.left, *, el.right]), " ")
end

function sqlrepr(def::Database.Default, pred::Predicate)::SqlPart
    if ==(pred.func, ==)
        op = :(=)
    else
        op = pred.func
    end
    sqlpart(sqlrepr.(Ref(def), [pred.left, op, pred.right]), " ")
end

function sqlrepr(def::Database.Default, clause::FromClause)::SqlPart
    if clause.__octo_as isa Nothing
         sqlpart(sqlrepr(def, clause.__octo_model))
    else
         sqlpart(sqlrepr.(Ref(def), [clause.__octo_model, AS, clause.__octo_as]), " ")
    end
end

function sqlrepr(def::Database.Default, subquery::SubQuery)::SqlPart
    query = subquery.__octo_query
    body = sqlpart(vcat(sqlrepr.(Ref(def), query)...), " ")
    part = sqlpart([
        SqlPartElement(:normal, '('),
        body,
        SqlPartElement(:normal, ')')], "")
    if subquery.__octo_as isa Nothing
        part
    else
        sqlpart([
            part,
            sqlrepr.(Ref(def), [AS, subquery.__octo_as])...
        ], " ")
    end
end

struct OverClauseError <: Exception
    msg
end

function sqlrepr(def::Database.Default, clause::OverClause)::SqlPart # throw OverClauseError
    if length(clause.__octo_query) >= 3 && clause.__octo_query[2] isa Keyword && clause.__octo_query[2].name == :OVER
        body = sqlpart([
            SqlPartElement(:normal, '('),
            sqlpart(sqlrepr.(Ref(def), clause.__octo_query[3:end]), " "),
            SqlPartElement(:normal, ')')], "")
        part = sqlpart([
            sqlrepr.(Ref(def), [clause.__octo_query[1], OVER])...,
            body
        ], " ")
        if clause.__octo_as isa Nothing
             part
        else
            sqlpart([
                part,
                sqlrepr.(Ref(def), [AS, clause.__octo_as])...
            ], " ")
        end
    else
        throw(OverClauseError(""))
    end
end

function sqlrepr(def::Database.Default, tup::Tuple)::SqlPart
    sqlpart(sqlrepr.(Ref(def), [tup...]), ", ")
end

function sqlrepr(def::Database.Default, tup::NamedTuple)::SqlPart
    sqlpart(sqlrepr.(Ref(def), map(kv -> Predicate(==, kv.first, kv.second), collect(pairs(tup)))), ", ")
end

function sqlrepr(def::Database.Default, enclosed::Enclosed)::SqlPart
    vals = sqlpart(sqlrepr.(Ref(def), [enclosed.values...]), ", ")
    if enclosed.values isa Vector{PlaceHolder}
        length(enclosed.values) == 1 && return vals
    end
    return sqlpart([
        SqlPartElement(:normal, '('),
        vals,
        SqlPartElement(:normal, ')')], "")
end

function sqlrepr(def::Database.Default, a::SQLAlias)::SqlPart
    sqlpart(vcat(sqlrepr(def, a.field), sqlrepr.(Ref(def), [AS, a.alias])), " ")
end

function sqlrepr(def::Database.Default, f::AggregateFunction)::SqlPart
    sqlpart([
        SqlPartElement(:yellow, f.name),
        SqlPartElement(:normal, '('),
        sqlrepr(def, f.field),
        SqlPartElement(:normal, ')')], "")
end

function sqlrepr(def::Database.Default, f::RankingFunction)::SqlPart
    sqlpart([
        SqlPartElement(:yellow, f.name),
        SqlPartElement(:normal, '('),
        SqlPartElement(:normal, ')')], "")
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
            printstyled(io, el.body; color=el.color)
        end
        length(part.elements) == idx || print(io, part.sep)
    end
end

# _to_sql

function _to_sql(db::DB, subquery::SubQuery)::String where DB <: Database.AbstractDatabase
    joinpart(sqlrepr(db, subquery))
end

function _to_sql(db::DB, query::Structured)::String where DB <: Database.AbstractDatabase
    nth = 1
    q = []
    for el in query
        if el isa Type{PlaceHolder}
            push!(q, _placeholder(db, nth))
            nth += 1
        elseif el isa Predicate && el.right isa Type{PlaceHolder}
            push!(q, Predicate(el.func, el.left, _placeholder(db, nth)))
            nth += 1
        else
            push!(q, el)
        end
    end
    joinpart(sqlpart(vcat(sqlrepr.(Ref(db), q)...), " "))
end

# _placeholder, _placeholders

function _placeholder(db::DB, nth::Int) where DB <: Database.AbstractDatabase
    PlaceHolder("?")
end

function _placeholders(db::DB, dims::Int) where DB <: Database.AbstractDatabase
    Enclosed(fill(_placeholder(db, 1), dims))
end

# _show

function Base.show(io::IO, mime::MIME"text/plain", query::Structured)
    db = current[:database]
    _show(io, mime, db, query)
end

function _show(io::IO, ::MIME"text/plain", db::DB, query::Structured) where DB <: Database.AbstractDatabase
    if any(x -> x isa SQLElement, query)
        printpart(io, sqlpart(vcat(sqlrepr.(Ref(db), query)...), " "))
    else
        Base.show(io, query)
    end
end


@keywords AND AS ASC BY CREATE DATABASE DELETE DESC DISTINCT DROP EXISTS FROM FULL GROUP
@keywords HAVING IF INNER INSERT INTO IS JOIN LEFT LIKE LIMIT NOT NULL OFFSET ON OR ORDER OUTER OVER
@keywords RIGHT SELECT SET TABLE UPDATE USING VALUES WHERE

@aggregates AVG COUNT SUM

@rankings DENSE_RANK RANK ROW_NUMBER

end # module Octo.AdapterBase
