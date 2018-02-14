# module Octo

abstract type SQLElement end

struct FromClause <: SQLElement
    __octo_model::Type
    __octo_as::Union{Symbol, Nothing}
end

struct Field <: SQLElement
    clause::FromClause
    name::Symbol
end

struct AggregateFunction <: SQLElement
    name::Symbol
    field
    as::Union{Symbol, Nothing}
end

struct Predicate <: SQLElement
    func::Function
    left::Union{Bool, Number, String, Symbol, Field, AggregateFunction, Predicate}
    right::Union{Bool, Number, String, Symbol, Field, AggregateFunction, Predicate}
end
