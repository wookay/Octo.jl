module Queryable # Octo

import ..Octo: Structured, FromItem, SubQuery, Field, SQLAlias, SQLExtract, SQLFunction, Predicate, Keyword
import Dates: CompoundPeriod
using Dates # DatePeriod, TimePeriod, TimeType

"""
    from(M::Type, alias=nothing)::FromItem
"""
function from(M::Type, alias=nothing)::FromItem
    FromItem(M, alias)
end

function Base.getproperty(clause::FromItem, field::Symbol)
     if field in (:__octo_model, :__octo_alias)
         getfield(clause, field)
     else
         Field(clause, field)
     end
end

"""
    from(query::Structured, alias=nothing)::SubQuery
"""
function from(query::Structured, alias=nothing)::SubQuery
    SubQuery(query, alias)
end

function Base.getproperty(clause::SubQuery, field::Symbol)
     if field in (:__octo_query, :__octo_alias)
         getfield(clause, field)
     else
         Field(clause, field)
     end
end


"""
    as(field::Union{Field, SQLFunction, Predicate}, alias::Symbol)::SQLAlias
"""
function as(field::Union{Field, SQLFunction, Predicate}, alias::Symbol)::SQLAlias
    SQLAlias(field, alias)
end


"""
    extract(field::Union{Keyword, Type{DP}, Type{TP}}, from::Union{Dates.DateTime, DP, TP, Dates.CompoundPeriod})::SQLExtract where DP <: Dates.DatePeriod where TP <: Dates.TimePeriod
"""
function extract(field::Union{Keyword, Type{DP}, Type{TP}}, from::Union{DateTime, <:TimeType, DP, TP, CompoundPeriod})::SQLExtract where DP <: DatePeriod where TP <: TimePeriod
    SQLExtract(field, from)
end

end # module Octo.Queryable
