module AdapterBase

module Database
abstract type AbstractDatabase end
const Default = Any
struct SQLDatabase <: AbstractDatabase end
struct SQLiteDatabase <: AbstractDatabase end
struct MySQLDatabase <: AbstractDatabase end
struct PostgreSQLDatabase <: AbstractDatabase end
end # module Octo.AdapterBase.Database

import ...Schema
import ...Queryable: Structured, FromClause, from
import ...Octo: SQLElement, Field, SQLAlias, AggregateFunction, Predicate, Raw, Enclosed, PlaceHolder, Keyword, KeywordAllKeyword, Aggregate
import ...Octo: @keywords, @aggregates

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
         sqlpart(sqlrepr(Ref(def), clause.__octo_model))
    else
         sqlpart(sqlrepr.(Ref(def), [clause.__octo_model, AS, clause.__octo_as]), " ")
    end
end

function sqlrepr(def::Database.Default, tup::Tuple)::SqlPart
    sqlpart(sqlrepr.(Ref(def), [tup...]), ", ")
end

function sqlrepr(def::Database.Default, tup::NamedTuple)::SqlPart
    sqlpart(sqlrepr.(def, map(kv -> Predicate(==, kv.first, kv.second), collect(pairs(tup)))), ", ")
end

function sqlrepr(def::Database.Default, enclosed::Enclosed)::SqlPart
    vals = sqlpart(sqlrepr.(def, [enclosed.values...]), ", ")
    if enclosed.values isa Vector{PlaceHolder}
        length(enclosed.values) == 1 && return vals
    end
    return sqlpart([
        SqlPartElement(:normal, '('),
        vals,
        SqlPartElement(:normal, ')')], "")
end

function sqlrepr(def::Database.Default, a::SQLAlias)::SqlPart
    sqlpart(vcat(sqlrepr(Ref(def), a.field), sqlrepr.(Ref(def), [AS, a.alias])), " ")
end

function sqlrepr(def::Database.Default, f::AggregateFunction)::SqlPart
    sqlpart([
        SqlPartElement(:yellow, f.name),
        SqlPartElement(:normal, '('),
        sqlrepr(def, f.field),
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

function _to_sql(db::DB, query::Structured)::String where DB <: Database.AbstractDatabase
    joinpart(sqlpart(vcat(sqlrepr.(Ref(db), query)...), " "))
end

function to_sql(query::Structured)::String
    _to_sql(SQL, query)
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
@keywords HAVING IF INNER INSERT INTO IS JOIN LEFT LIKE LIMIT NOT NULL OFFSET ON OR ORDER OUTER
@keywords RIGHT SELECT SET TABLE UPDATE USING VALUES WHERE

@aggregates AVG COUNT SUM

end # module Octo.AdapterBase
