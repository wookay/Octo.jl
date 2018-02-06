module SQL

using ...Queryable: Structured, FromClause
using ...Schema
import ...Octo: Field, AggregateFunction, Predicate
import ..Database

export to_sql
include("sql_exports.jl")

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
(a::Aggregate)(field) = AggregateFunction(a.name, field)

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

function sqlrepr(::Database.Default, M::Type)::SqlElement
    Tname = Base.typename(M)
    if haskey(Schema.tables, Tname)
        SqlElement(:normal, Schema.tables[Tname])
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

function sqlrepr(def::Database.Default, f::AggregateFunction)::SqlPart
    sqlpart([
        SqlElement(:yellow, f.name),
        SqlElement(:normal, '('),
        sqlrepr(def, f.field),
        SqlElement(:normal, ')')], "")
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

function _to_sql(db, query::Structured)::String
    joinpart(sqlpart(vcat(sqlrepr.(db, query)...), " "))
end

function to_sql(query::Structured)::String
    _to_sql(SQL, query)
end

function _show(io::IO, ::MIME"text/plain", db, query::Structured)
    if any(x -> x isa Keyword || x isa FromClause, query)
        printpart(io, sqlpart(vcat(sqlrepr.(db, query)...), " "))
    else
        Base._display(io, query)
    end
end

function Base.show(io::IO, mime::MIME"text/plain", query::Structured)
    _show(io, mime, SQL, query)
end

macro keywords(args...)
    esc(keywords(args))
end
keywords(s) = :(($(s...),) = $(map(Keyword, s)))

macro aggregates(args...)
    esc(aggregates(args))
end
aggregates(s) = :(($(s...),) = $(map(Aggregate, s)))

function Base.:*(left::Keyword, right::Keyword)
    KeywordAllKeyword(left, right)
end

@keywords SELECT DISTINCT FROM AS WHERE EXISTS AND OR NOT
@keywords INNER OUTER LEFT RIGHT FULL JOIN ON USING
@keywords GROUP BY HAVING ORDER ASC DESC
@aggregates COUNT SUM AVG

end # module Octo.Adapters.SQL
