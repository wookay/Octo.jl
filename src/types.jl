# module Octo

# SQLElement
abstract type SQLElement end

const Structured = Array # Union{<:SQLElement, Any}

struct FromClause <: SQLElement
    __octo_model::Type
    __octo_as::Union{Symbol, Nothing}
end

struct SubQuery <: SQLElement
    __octo_query::Structured
    __octo_as::Union{Symbol, Nothing}
end

struct WindowFrame <: SQLElement
    __octo_query::Structured
    __octo_as::Union{Symbol, Nothing}
end

struct SQLFunction <: SQLElement
    name::Symbol
    fields::Tuple
end
(f::SQLFunction)(args...) = SQLFunction(f.name, args)

struct Field <: SQLElement
    clause::Union{FromClause, SubQuery, WindowFrame}
    name::Symbol
end

struct Keyword <: SQLElement
    name::Symbol
end

"""
    Octo.PlaceHolder
"""
struct PlaceHolder <: SQLElement
    body::String
end

const PredicateValueTypes = Union{Bool, Number, String, Symbol, Deps.Dates.Day, <: SQLElement}

struct Predicate <: SQLElement
    func::Function
    left::PredicateValueTypes
    right::Union{PredicateValueTypes, Type{PlaceHolder}}
end

struct SQLAlias <: SQLElement
    field::Union{Field, SQLFunction, Predicate}
    alias::Symbol
end

struct SQLOver <: SQLElement
    field::SQLFunction
    query::Union{WindowFrame,Vector}
end

# DatePeriod     - Year Month Day
# TimePeriod     - Hour Minute Second
# CompoundPeriod
struct SQLExtract <: SQLElement
    field::Union{Keyword, Type{DP}, Type{TP}}               where DP <: Deps.DatePeriod where TP <: Deps.TimePeriod
    from::Union{Deps.DateTime, DP, TP, Deps.CompoundPeriod} where DP <: Deps.DatePeriod where TP <: Deps.TimePeriod
end

struct Raw <: SQLElement
    string::String
end

struct Enclosed <: SQLElement
    values::Vector
end

struct KeywordAllKeyword <: SQLElement
    left::Keyword
    right::Keyword
end

# module Octo
