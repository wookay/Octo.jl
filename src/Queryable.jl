module Queryable # Octo

import ..Octo: FromClause, SubQuery, OverClause, OverClauseError, Field, SQLAlias, Structured, SQLFunction

"""
    from(M::Type, as=nothing)::FromClause
"""
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

"""
    from(query::Structured, as=nothing)::SubQuery
"""
function from(query::Structured, as=nothing)::SubQuery
    SubQuery(query, as)
end

function Base.getproperty(clause::SubQuery, field::Symbol)
     if field in (:__octo_query, :__octo_as)
         getfield(clause, field)
     else
         Field(clause, field)
     end
end

"""
    window(query::Structured, as=nothing):OverClause
"""
function window(query::Structured, as=nothing)::OverClause
    OverClause(query, as)
end

function Base.getproperty(clause::OverClause, field::Symbol)
     if field in (:__octo_query, :__octo_as)
         getfield(clause, field)
     else
         Field(clause, field)
     end
end

"""
    as(field::Union{Field, SQLFunction}, alias::Symbol)::SQLAlias
"""
function as(field::Union{Field, SQLFunction}, alias::Symbol)::SQLAlias
    SQLAlias(field, alias)
end

end # module Octo.Queryable
