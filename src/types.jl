# module Octo

struct FromClause
    __octo_model::Type
    __octo_as::Union{Symbol, Nothing}
end

struct Field
    clause::FromClause
    name::Symbol
end

struct AggregateFunction
    name::Symbol
    field
end

struct Predicate
    func::Function
    left::Union{Bool, Number, String, Field, AggregateFunction, Predicate}
    right::Union{Bool, Number, String, Field, AggregateFunction, Predicate}
end
