# module Octo

module Queryable

import ..Octo: FromClause, Field, SQLAlias, AggregateFunction, Structured

"""
    from(M::Type, as=nothing)::FromClause
"""
function from(M::Type, as=nothing)::FromClause
    FromClause(M, as)
end

"""
    as(field::Union{Field, AggregateFunction}, alias::Symbol)::SQLAlias
"""
function as(field::Union{Field, AggregateFunction}, alias::Symbol)::SQLAlias
    SQLAlias(field, alias)
end

function Base.getproperty(clause::FromClause, field::Symbol)
     if field in (:__octo_model, :__octo_as)
         getfield(clause, field)
     else
         Field(clause, field)
     end
end

end # module Octo.Queryable