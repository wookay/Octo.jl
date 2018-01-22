# module Octo

module Queryable

import ..Octo: Model, FromClause, Field

function from(::Type{M}, as=nothing)::FromClause where M <: Model
    FromClause(M, as)
end

function Base.getproperty(clause::FromClause, field::Symbol)
     if field in (:__octo_model, :__octo_as)
         getfield(clause, field)
     else
         Field(clause, field)
     end
end

const Statement = Array

end # module Octo.Queryable
