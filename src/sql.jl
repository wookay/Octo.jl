module SQL

import Base: getindex, typed_hcat, typed_vcat, typed_hvcat, *, ==, &, |, !, <, >, <=, >=
import ..Octo: Model, Field, SELECT, DISTINCT, FROM
import ..Octo: SqlFunc
import ..Octo: Predicate
import ..Octo: modelstore

struct SelectAllFrom
end

struct DistinctAllFrom
end

function sqlstring(args...)::String
    join(args, " ")
end

function fieldjoin(f::Function, fields::Tuple)::String
    join(f.(fields), ", ")
end

fieldname(field::Field)::String = string(field.fieldname)
fieldname(sf::SqlFunc)::String = sqlfuncrepr(fieldname, sf)

function fullname(field::Field)::String
    typ = Base.typename(field.table)
    table_name = modelstore[typ][:table_name]
    string(table_name, '.', field.fieldname) 
end
fullname(sf::SqlFunc)::String = sqlfuncrepr(fullname, sf)

### sqlfuncrerpr

function sqlfuncrepr(f::Function, sf::SqlFunc)::String
    string(Base.function_name(sf.f), '(', fieldjoin(f, sf.args), ')')
end

### sqlrepr

function sqlrepr(::Function, k::Function)
    Base.function_name(k)
end

function sqlrepr(f::Function, sf::SqlFunc)
    sqlfuncrepr(f, sf)
end

function sqlrepr(f, n::Number)
    n
end

function sqlrepr(::Function, val::String)
    string("'", val, "'")
end

function sqlrepr(::Function, m::M) where M <: Model
    typ = Base.typename(M)
    modelstore[typ][:table_name]
end

function sqlrepr(f::Function, field::Field)
    f(field)
end

function sqlrepr(f::Function, fields::Tuple)
    fieldjoin(f, fields)
end

function sqlrepr(f::Function, pred::Predicate)
    if ==(pred.f, !)
        op = "NOT"
        sqlstring(op, sqlrepr(f, pred.field2))
    else
        if ==(pred.f, ==)
            op = "="
        elseif ==(pred.f, &)
            op = "AND"
        elseif ==(pred.f, |)
            op = "OR"
        else
            op = sqlrepr(f, pred.f)
        end
        sqlstring(sqlrepr(f, pred.field1), op, sqlrepr(f, pred.field2))
    end
end

const SqlFieldType = Union{typeof(*),Field,SqlFunc,Tuple}

### getindex, typed_hcat, typed_vcat, typed_hvcat - fieldname

function getindex(::typeof(repr), m::M) where M <: Model
    sqlrepr(fieldname, m)
end


function typed_hcat(::typeof(repr), s1::Function, m::M) where M <: Model
    sqlstring(sqlrepr.(fieldname, (s1, m))...)
end

function typed_vcat(::typeof(repr), s1::Function, m::M) where M <: Model
    typed_hcat(repr, s1, m)
end


function typed_hcat(::typeof(repr), ::SelectAllFrom, m::M, args...) where M <: Model
    sqlstring(sqlrepr.(fieldname, (SELECT, *, FROM, m, args...))...)
end

function typed_vcat(::typeof(repr), s::SelectAllFrom, m::M, args...) where M <: Model
    typed_hcat(repr, s, m, args...)
end

function typed_hvcat(::typeof(repr), ::Tuple, s::SelectAllFrom, m::M, args...) where M <: Model
    typed_hcat(repr, s, m, args...)
end


function typed_hcat(::typeof(repr), s1::Function, ::DistinctAllFrom, m::M, args...) where M <: Model
    sqlstring(sqlrepr.(fieldname, (s1, DISTINCT, *, FROM, m, args...))...)
end

function typed_hvcat(::typeof(repr), ::Tuple, s1::Function, d::DistinctAllFrom, m::M, args...) where M <: Model
    typed_hcat(repr, s1, d, m, args...)
end


function typed_hcat(::typeof(repr), s1::Function, field::SqlFieldType, f1::Function, m::M, args...) where M <: Model
    sqlstring(sqlrepr.(fieldname, (s1, field, f1, m, args...))...)
end

function typed_vcat(::typeof(repr), s1::Function, field::SqlFieldType, f1::Function, m::M, args...) where M <: Model
    typed_hcat(repr, s1, field, f1, m, args...)
end

function typed_hvcat(::typeof(repr), ::Tuple, s1::Function, field::SqlFieldType, f1::Function, m::M, args...) where M <: Model
    typed_hcat(repr, s1, field, f1, m, args...)
end


function typed_hcat(::typeof(repr), s1::Function, s2::Function, field::SqlFieldType, f1::Function, m::M, args...) where M <: Model
    sqlstring(sqlrepr.(fieldname, (s1, s2, field, f1, m, args...))...)
end

function typed_vcat(::typeof(repr), s1::Function, s2::Function, field::SqlFieldType, f1::Function, m::M, args...) where M <: Model
    typed_hcat(repr, s1, s2, field, f1, m, args...)
end

function typed_hvcat(::typeof(repr), ::Tuple, s1::Function, s2::Function, field::SqlFieldType, f1::Function, m::M, args...) where M <: Model
    typed_hcat(repr, s1, s2, field, f1, m, args...)
end


### typed_hcat, typed_vcat, typed_hvcat - fullname

function typed_hcat(::typeof(repr), ::SelectAllFrom, m1::M1, w1::Function, w2::Function, m2::M2, args...) where M1 <: Model where M2 <: Model
    sqlstring(sqlrepr.(fullname, (SELECT, *, FROM, m1, w1, w2, m2, args...))...)
end


function typed_hcat(::typeof(repr), s1::Function, ::DistinctAllFrom, m1::M1, w1::Function, w2::Function, m2::M2, args...) where M1 <: Model where M2 <: Model
    sqlstring(sqlrepr.(fullname, (s1, DISTINCT, *, FROM, m1, w1, w2, m2, args...))...)
end


function typed_hcat(::typeof(repr), s1::Function, field::SqlFieldType, f1::Function, m1::M1, w1::Function, w2::Function, m2::Union{Predicate,M2}, args...) where M1 <: Model where M2 <: Model
    sqlstring(sqlrepr.(fullname, (s1, field, f1, m1, w1, w2, m2, args...))...)
end

function typed_hvcat(::typeof(repr), ::NTuple, s1::Function, field::SqlFieldType, f1::Function, m1::M1, w1::Function, w2::Function, m2::Union{Predicate,M2}, args...) where M1 <: Model where M2 <: Model
    typed_hcat(repr, s1, field, f1, m1, w1, w2, m2, args...)
end


function typed_hcat(::typeof(repr), s1::Function, s2::Function, field::SqlFieldType, f1::Function, m1::M1, w1::Function, w2::Function, m2::Union{Predicate,M2}, args...) where M1 <: Model where M2 <: Model
    sqlstring(sqlrepr.(fullname, (s1, s2, field, f1, m1, w1, w2, m2, args...))...)
end

function typed_vcat(::typeof(repr), s1::Function, s2::Function, field::SqlFieldType, f1::Function, m1::M1, w1::Function, w2::Function, m2::Union{Predicate,M2}, args...) where M1 <: Model where M2 <: Model
    typed_hcat(repr, s1, s2, field, f1, m1, w1, w2, m2, args...)
end


function *(::typeof(SELECT), ::typeof(FROM))
    SelectAllFrom()
end

function *(::typeof(DISTINCT), ::typeof(FROM))
    DistinctAllFrom()
end

### predicates

==(f1::Field, f2::Field)          = Predicate(==, f1, f2)
==(f1::Field, val::Number)        = Predicate(==, f1, val)
==(f1::Field, val::String)        = Predicate(==, f1, val)
(&)(p1::Predicate, p2::Predicate) = Predicate(&, p1, p2)
(|)(p1::Predicate, p2::Predicate) = Predicate(|, p1, p2)
(!)(p2::Predicate)                = Predicate(!, nothing, p2)

<(lhs::Union{Field,SqlFunc}, rhs::Union{Number,Field,SqlFunc}) = Predicate(<, lhs, rhs)
<(lhs::Union{Number, Field, SqlFunc}, rhs::Union{Field,SqlFunc}) = Predicate(<, lhs, rhs)

>(lhs::Union{Field,SqlFunc}, rhs::Union{Number,Field,SqlFunc}) = Predicate(>, lhs, rhs)
>(lhs::Union{Number, Field, SqlFunc}, rhs::Union{Field,SqlFunc}) = Predicate(>, lhs, rhs)

<=(lhs::Union{Field,SqlFunc}, rhs::Union{Number,Field,SqlFunc}) = Predicate(<=, lhs, rhs)
<=(lhs::Union{Number, Field, SqlFunc}, rhs::Union{Field,SqlFunc}) = Predicate(<=, lhs, rhs)

>=(lhs::Union{Field,SqlFunc}, rhs::Union{Number,Field,SqlFunc}) = Predicate(>=, lhs, rhs)
>=(lhs::Union{Number, Field, SqlFunc}, rhs::Union{Field,SqlFunc}) = Predicate(>=, lhs, rhs)

end # Octo.SQL
