module SQL

import Base: getindex, typed_hcat, *, ==
import ..Octo: Model, Field, SELECT, FROM
import ..Octo: modelstore

struct SelectAllFrom
end

struct Predicate
    f
    field1::Field
    field2::Field
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

function fieldname(field::Field)
    string(field.fieldname) 
end

function fullname(field::Field)
    typ = Base.typename(field.table)
    table_name = modelstore[typ][:table_name]
    string(table_name, '.', field.fieldname) 
end

function fieldrepr(f, field::Field)
    f(field)
end

function fieldrepr(f, fields::Tuple{Field,Field})
    fieldjoin(f, fields...)
end

function fieldrepr(f, pred::Predicate)
    if ==(pred.f, ==)
        op = "="
    else
        op = Base.function_name(pred.f)
    end
    sqlstring(fieldrepr(f, pred.field1), op, fieldrepr(f, pred.field2))
end

### typed_hcat

function typed_hcat(::typeof(repr), k1::Function, m::M) where M <: Model
    sqlstring(repr[k1], repr[m])
end

function typed_hcat(::typeof(repr), clause::SelectAllFrom, m::M) where M <: Model
    sqlstring("SELECT", "*", "FROM", repr[m])
end

function typed_hcat(::typeof(repr), k1::Function, field::Field, k2::Function, m::M) where M <: Model
    sqlstring(repr[k1], fieldrepr(fieldname, field), repr[k2], repr[m])
end

function typed_hcat(::typeof(repr), k1::Function, fields::Tuple{Field,Field}, k2::Function, m::M) where M <: Model
    sqlstring(repr[k1], fieldrepr(fieldname, fields), repr[k2], repr[m])
end

function typed_hcat(::typeof(repr), k1::Function, fields::Tuple{Field,Field}, k2::Function, m1::M1, k3::Function, k4::Function, m2::M2, k5::Function, pred::Predicate) where M1 <: Model where M2 <: Model
    sqlstring(repr[k1], fieldrepr(fullname, fields), repr[k2], repr[m1], repr[k3], repr[k4], repr[m2], repr[k5], fieldrepr(fullname, pred))
end

function *(::typeof(SELECT), ::typeof(FROM))
    SelectAllFrom()
end

function ==(f1::Field, f2::Field)
    Predicate(==, f1, f2)
end

end # Octo.SQL
