module SQL

import Base: getindex, typed_hcat, *
import ..Octo: Model, Field, SELECT, FROM

function sqlstring(args...)
    join(args, " ")
end

function getindex(::typeof(repr), ::M) where M <: Model
    Base.getproperty(M, :table_name)
end

function typed_hcat(::typeof(repr), clause::Function, m::M) where M <: Model
    sqlstring(Base.function_name(clause), repr[m])
end

struct SelectAllFrom
end

function typed_hcat(::typeof(repr), clause::SelectAllFrom, m::M) where M <: Model
    sqlstring("SELECT", "*", "FROM", repr[m])
end

function typed_hcat(::typeof(repr), ::Function, field::Field, ::Function, m::M) where M <: Model
    sqlstring("SELECT", field.name, "FROM", repr[m])
end

function fieldjoin(fields...)
    f = x->x.name
    join(f.(fields), ", ")
end

function typed_hcat(::typeof(repr), ::Function, fields::Tuple{Field,Field}, ::Function, m::M) where M <: Model
    sqlstring("SELECT", fieldjoin(fields...), "FROM", repr[m])
end

function *(::typeof(SELECT), ::typeof(FROM))
    SelectAllFrom()
end

end # Octo.SQL
