# module Octo

module Queryable

import ..Octo: FromClause, Field

function from(M::Type, as=nothing)::FromClause
    FromClause(M, as)
end

function Base.getproperty(clause::FromClause, field::Symbol)
     if field in (:__octo_model, :__octo_as)
         getfield(clause, field)
     else
         Field(clause, field)
     end
end

const Structured = Array

end # module Octo.Queryable
