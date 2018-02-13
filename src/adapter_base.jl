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
import ...Octo: Field, AggregateFunction, Predicate

const current = Dict{Symbol, Database.AbstractDatabase}(
    :database => Database.SQLDatabase()
)

struct Enclosed
    values
end

struct QuestionMark
end

struct SqlElement
    color::Union{Symbol, Int}
    body
end

struct SqlPart
    elements::Vector{Union{SqlPart, SqlElement}}
    sep::String
end

struct Keyword
    name::Symbol
end

struct Aggregate
    name::Symbol
end
(a::Aggregate)(field, as=nothing) = AggregateFunction(a.name, field, as)

struct KeywordAllKeyword
    left::Keyword
    right::Keyword
end

# sqlpart
function sqlpart(element::SqlElement)::SqlPart
    SqlPart([element], "")
end

function sqlpart(elements::Vector, sep::String)::SqlPart
    SqlPart(elements, sep)
end

# sqlrepr - SqlElement

sqlrepr(::Database.Default, el::Keyword)::SqlElement = SqlElement(:cyan, el.name)
sqlrepr(::Database.Default, sym::Symbol)::SqlElement = SqlElement(:normal, sym)
sqlrepr(::Database.Default, num::Number)::SqlElement = SqlElement(:normal, num)
sqlrepr(::Database.Default, f::Function)::SqlElement = SqlElement(:normal, f)
sqlrepr(::Database.Default, ::Type{QuestionMark})::SqlElement = SqlElement(:normal, '?')

function sqlrepr(::Database.Default, M::Type)::SqlElement
    Tname = Base.typename(M)
    if haskey(Schema.tables, Tname)
        info = Schema.tables[Tname]
        SqlElement(:normal, info[:table_name])
    else
        name = nameof(M)
        throw(Schema.TableNameError("""Provide schema table_name by `Schema.model($name, table_name="tbl")`"""))
    end
end

function sqlrepr(::Database.Default, str::String)::SqlPart
    quot = SqlElement(:light_magenta, "'")
    sqlpart([quot, SqlElement(:light_magenta, str), quot], "")
end

function sqlrepr(::Database.Default, field::Field)::SqlPart
    if field.clause.__octo_as isa Nothing
        sqlpart(SqlElement(:normal, field.name))
    else
        sqlpart([
            SqlElement(:normal, field.clause.__octo_as),
            SqlElement(:normal, '.'),
            SqlElement(:normal, field.name)], "")
    end
end

# sqlrepr - SqlPart

function sqlrepr(def::Database.Default, el::KeywordAllKeyword)::SqlPart
    sqlpart(sqlrepr.(def, [el.left, *, el.right]), " ")
end

function sqlrepr(def::Database.Default, pred::Predicate)::SqlPart
    if ==(pred.func, ==)
        op = :(=)
    else
        op = pred.func
    end
    sqlpart(sqlrepr.(def, [pred.left, op, pred.right]), " ")
end

function sqlrepr(def::Database.Default, clause::FromClause)::SqlPart
    if clause.__octo_as isa Nothing
         sqlpart(sqlrepr(def, clause.__octo_model))
    else
         sqlpart(sqlrepr.(def, [clause.__octo_model, AS, clause.__octo_as]), " ")
    end
end

function sqlrepr(def::Database.Default, tup::Tuple)::SqlPart
    sqlpart(sqlrepr.(def, [tup...]), ", ")
end

function sqlrepr(def::Database.Default, tup::NamedTuple)::SqlPart
    sqlpart(sqlrepr.(def, map(kv -> Predicate(==, kv.first, kv.second), collect(pairs(tup)))), ", ")
end

function sqlrepr(def::Database.Default, enclosed::Enclosed)::SqlPart
    vals = sqlpart(sqlrepr.(def, [enclosed.values...]), ", ")
    sqlpart([
        SqlElement(:normal, '('),
        vals,
        SqlElement(:normal, ')')], "")
end

function sqlrepr(def::Database.Default, f::AggregateFunction)::SqlPart
    part = sqlpart([
        SqlElement(:yellow, f.name),
        SqlElement(:normal, '('),
        sqlrepr(def, f.field),
        SqlElement(:normal, ')')], "")
    if f.as isa Nothing
        part
    else
        sqlpart(vcat(part, sqlrepr.(def, [AS, f.as])), " ")
    end
end

function joinpart(part::SqlPart)::String
    join(map(part.elements) do el
        if el isa SqlPart
            joinpart(el)
        elseif el isa SqlElement
            el.body
        end
    end, part.sep)
end

function printpart(io::IO, part::SqlPart)
    for (idx, el) in enumerate(part.elements)
        if el isa SqlPart
            printpart(io, el)
        elseif el isa SqlElement
            printstyled(io, el.body; color=el.color)
        end
        length(part.elements) == idx || print(io, part.sep)
    end
end

# _to_sql

function _to_sql(db::DB, query::Structured)::String where DB <: Database.AbstractDatabase
    joinpart(sqlpart(vcat(sqlrepr.(db, query)...), " "))
end

function to_sql(query::Structured)::String
    _to_sql(SQL, query)
end

# _show

function Base.show(io::IO, mime::MIME"text/plain", query::Structured)
    db = current[:database]
    _show(io, mime, db, query)
end

function _show(io::IO, ::MIME"text/plain", db::DB, query::Structured) where DB <: Database.AbstractDatabase
    if any(x -> x isa Keyword || x isa KeywordAllKeyword || x isa AggregateFunction || x isa FromClause, query)
        printpart(io, sqlpart(vcat(sqlrepr.(db, query)...), " "))
    else
        Base.show(io, query)
    end
end


# @keywords

macro keywords(args...)
    esc(keywords(args))
end
keywords(s) = :(($(s...),) = $(map(Keyword, s)))


# @aggregates

macro aggregates(args...)
    esc(aggregates(args))
end
aggregates(s) = :(($(s...),) = $(map(Aggregate, s)))

function Base.:*(left::Keyword, right::Keyword)
    KeywordAllKeyword(left, right)
end


@keywords SELECT DISTINCT FROM AS WHERE LIKE EXISTS AND OR NOT LIMIT OFFSET INTO
@keywords INNER OUTER LEFT RIGHT FULL JOIN ON USING
@keywords GROUP BY HAVING ORDER ASC DESC

@aggregates COUNT SUM AVG

end # module Octo.AdapterBase
