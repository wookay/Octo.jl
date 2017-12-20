module SQL

import Base: getindex, typed_hcat, *, ==, &, |, !, <, >, <=, >=
import ..Octo: Model, Field, SELECT, DISTINCT, FROM
import ..Octo: Predicate
import ..Octo: modelstore

struct SelectAllFrom
end

struct DistinctAllFrom
end

function sqlstring(args...)
    join(args, " ")
end

function fieldjoin(f, fields...)
    join(f.(fields), ", ")
end

### getindex repr

function getindex(::typeof(repr), ::M) where M <: Model
    typ = Base.typename(M)
    modelstore[typ][:table_name]
end

function getindex(::typeof(repr), f::Function)
    Base.function_name(f)
end

function getindex(::typeof(repr), pred::Predicate)
    fieldrepr(fieldname, pred)
end

function getindex(::typeof(repr), val::Number)
    val
end

function fieldname(field::Field)
    string(field.fieldname) 
end

function fullname(field::Field)
    typ = Base.typename(field.table)
    table_name = modelstore[typ][:table_name]
    string(table_name, '.', field.fieldname) 
end

### fieldrepr

function fieldrepr(f, field::Field)
    f(field)
end

function fieldrepr(f, val::Number)
    val
end

function fieldrepr(f, val::String)
    string("'", val, "'")
end

function fieldrepr(f, fields::Tuple)
    fieldjoin(f, fields...)
end

function fieldrepr(f, pred::Predicate)
    if ==(pred.f, !)
        op = "NOT"
        sqlstring(op, fieldrepr(f, pred.field2))
    else
        if ==(pred.f, ==)
            op = "="
        elseif ==(pred.f, &)
            op = "AND"
        elseif ==(pred.f, |)
            op = "OR"
        else
            op = Base.function_name(pred.f)
        end
        sqlstring(fieldrepr(f, pred.field1), op, fieldrepr(f, pred.field2))
    end
end

### sqlrepr

function sqlrepr(f, k::Function)
    repr[k]
end

function sqlrepr(f, m::M) where M <: Model
    repr[m]
end

function sqlrepr(f, n::Number)
    repr[n]
end

function sqlrepr(f, field::Field)
    fieldrepr(f, field)
end

function sqlrepr(f, fields::Tuple)
    fieldrepr(f, fields)
end

function sqlrepr(f, pred::Predicate)
    fieldrepr(f, pred)
end

### typed_hcat - fieldname

function typed_hcat(::typeof(repr), s1::Function, m::M) where M <: Model
    sqlstring(sqlrepr.(fieldname, (s1, m))...)
end

function typed_hcat(::typeof(repr), ::SelectAllFrom, m::M, args...) where M <: Model
    sqlstring(sqlrepr.(fieldname, (SELECT, *, FROM, m, args...))...)
end

function typed_hcat(::typeof(repr), s1::Function, ::DistinctAllFrom, m::M, args...) where M <: Model
    sqlstring(sqlrepr.(fieldname, (s1, DISTINCT, *, FROM, m, args...))...)
end

function typed_hcat(::typeof(repr), s1::Function, field::Field, f1::Function, m::M, args...) where M <: Model
    sqlstring(sqlrepr.(fieldname, (s1, field, f1, m, args...))...)
end

function typed_hcat(::typeof(repr), s1::Function, fields::Tuple, f1::Function, m::M, args...) where M <: Model
    sqlstring(sqlrepr.(fieldname, (s1, fields, f1, m, args...))...)
end

function typed_hcat(::typeof(repr), s1::Function, s2::Function, field::Field, f1::Function, m::M, args...) where M <: Model
    sqlstring(sqlrepr.(fieldname, (s1, s2, field, f1, m, args...))...)
end

function typed_hcat(::typeof(repr), s1::Function, s2::Function, fields::Tuple, f1::Function, m::M, args...) where M <: Model
    sqlstring(sqlrepr.(fieldname, (s1, s2, fields, f1, m, args...))...)
end

### typed_hcat - fullname

function typed_hcat(::typeof(repr), ::SelectAllFrom, m1::M1, w1::Function, w2::Function, m2::M2, args...) where M1 <: Model where M2 <: Model
    sqlstring(sqlrepr.(fullname, (SELECT, *, FROM, m1, w1, w2, m2, args...))...)
end

function typed_hcat(::typeof(repr), s1::Function, ::DistinctAllFrom, m1::M1, w1::Function, w2::Function, m2::M2, args...) where M1 <: Model where M2 <: Model
    sqlstring(sqlrepr.(fullname, (s1, DISTINCT, *, FROM, m1, w1, w2, m2, args...))...)
end

function typed_hcat(::typeof(repr), s1::Function, field::Field, f1::Function, m1::M1, w1::Function, w2::Function, m2::M2, args...) where M1 <: Model where M2 <: Model
    sqlstring(sqlrepr.(fullname, (s1, field, f1, m1, w1, w2, m2, args...))...)
end

function typed_hcat(::typeof(repr), s1::Function, fields::Tuple, f1::Function, m1::M1, w1::Function, w2::Function, m2::M2, args...) where M1 <: Model where M2 <: Model
    sqlstring(sqlrepr.(fullname, (s1, fields, f1, m1, w1, w2, m2, args...))...)
end

function *(::typeof(SELECT), ::typeof(FROM))
    SelectAllFrom()
end

function *(::typeof(DISTINCT), ::typeof(FROM))
    DistinctAllFrom()
end

### predicates

function ==(f1::Field, f2::Field)
    Predicate(==, f1, f2)
end

function ==(f1::Field, val::Number)
    Predicate(==, f1, val)
end

function ==(f1::Field, val::String)
    Predicate(==, f1, val)
end

function (&)(p1::Predicate, p2::Predicate)
    Predicate(&, p1, p2)
end

function (|)(p1::Predicate, p2::Predicate)
    Predicate(|, p1, p2)
end

function (!)(p2::Predicate)
    Predicate(!, nothing, p2)
end

function <(field::Field, n::Number)
    Predicate(<, field, n)
end

function <(n::Number, field::Field)
    Predicate(<, n, field)
end

function >(field::Field, n::Number)
    Predicate(>, field, n)
end

function >(n::Number, field::Field)
    Predicate(>, n, field)
end

function >=(n::Number, field::Field)
    Predicate(>=, n, field)
end

function >=(field::Field, n::Number)
    Predicate(>=, field, n)
end

function <=(n::Number, field::Field)
    Predicate(<=, n, field)
end

function <=(field::Field, n::Number)
    Predicate(<=, field, n)
end

end # Octo.SQL
