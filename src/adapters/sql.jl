module SQL

using ...Queryable: Statement, FromClause
using ...Schema
import ...Octo: Model, Field, Predicate, SchemaError
import ..Database

export to_sql
export SELECT, FROM, AS, WHERE

struct SelectAllFrom
end

struct Keyword
    name::Symbol
end

function sqlstring(args)
    join(args, " ")
end

function sqlrepr(def::Database.Default, el::SelectAllFrom)
    sqlrepr.(def, [SELECT, *, FROM])
end

function sqlrepr(::Database.Default, el::Keyword)
    el.name
end

function sqlrepr(::Database.Default, sym::Symbol)
    String(sym)
end

function sqlrepr(::Database.Default, num::Number)
    string(num)
end

function sqlrepr(::Database.Default, field::Field)
    field.clause.__octo_as isa Nothing ? String(field.name) :
                                         string(field.clause.__octo_as, '.', field.name)
end

function sqlrepr(def::Database.Default, pred::Predicate)
    if ==(pred.func, ==)
        op = :(=)
    else
        op = pred.func
    end
    sqlrepr.(def, [pred.field1, op, pred.field2])
end

function sqlrepr(def::Database.Default, clause::FromClause)
    clause.__octo_as isa Nothing ? sqlrepr(def, clause.__octo_model) :
                                   sqlrepr.(def, [clause.__octo_model, AS, clause.__octo_as])
end

function sqlrepr(def::Database.Default, tup::Tuple)
    join(sqlrepr.(def, tup), ", ")
end

function sqlrepr(::Database.Default, ::typeof(*))
    string(*)
end

function sqlrepr(::Database.Default, ::Type{M}) where M <: Model
    name = Base.typename(M)
    if haskey(Schema.tables, name)
        Schema.tables[name]
    else
        throw(SchemaError(""))
    end
end

function to_sql(stmt::Statement)
    sqlstring(vcat(sqlrepr.(SQL, stmt)...))
end

macro keywords(args...)
    esc(keywords(args))
end
keywords(s) = :(($(s...),) = $(map(Keyword, s)))

function Base.:*(l::Keyword, r::Keyword)
    l.name == :SELECT && r.name == :FROM && SelectAllFrom()
end

@keywords SELECT FROM AS WHERE

end # module Octo.Adapters.SQL
