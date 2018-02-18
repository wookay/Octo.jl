# module Octo

# SQLElement
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

struct Raw <: SQLElement
    string::String
end

struct Enclosed <: SQLElement
    values
end

struct QuestionMark <: SQLElement
end

struct Keyword <: SQLElement
    name::Symbol
end

struct KeywordAllKeyword <: SQLElement
    left::Keyword
    right::Keyword
end

struct Aggregate
    name::Symbol
end
(a::Aggregate)(field, as=nothing) = AggregateFunction(a.name, field, as)

const Structured = Array # Union{<:SQLElement, Any}
