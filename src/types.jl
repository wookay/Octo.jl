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

struct OverClause <: SQLElement
    __octo_query::Structured
    __octo_as::Union{Symbol, Nothing}
end

struct OverClauseError <: Exception
    msg
end

struct Field <: SQLElement
    clause::Union{FromClause, SubQuery, OverClause}
    name::Symbol
end

struct SQLAlias <: SQLElement
    field
    alias::Symbol
end

"""
    Octo.PlaceHolder
"""
struct PlaceHolder <: SQLElement
    body::String
end

const PredicateValueTypes = Union{Bool, Number, String, Symbol, Dates.Day, <: SQLElement}

struct Predicate <: SQLElement
    func::Function
    left::PredicateValueTypes
    right::Union{PredicateValueTypes, Type{PlaceHolder}}
end

struct Raw <: SQLElement
    string::String
end

struct Enclosed <: SQLElement
    values::Vector
end

struct Keyword <: SQLElement
    name::Symbol
end

struct KeywordAllKeyword <: SQLElement
    left::Keyword
    right::Keyword
end

struct SQLFunction <: SQLElement
    name::Symbol
    fields::Tuple
end
(f::SQLFunction)(args...) = SQLFunction(f.name, args)

# module Octo
