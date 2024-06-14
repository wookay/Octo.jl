# module Octo

# SQLElement
abstract type SQLElement end

const Structured = Array # Union{<:SQLElement, Any}

struct FromItem <: SQLElement
    __octo_model::Type
    __octo_alias::Union{Symbol, Nothing}
end

struct SubQuery <: SQLElement
    __octo_query::Structured
    __octo_alias::Union{Symbol, Nothing}
end

struct SQLFunction <: SQLElement
    name::Symbol
    args::Tuple
    kwargs::Base.Pairs
end

struct SQLFunctionName <: SQLElement
    name::Symbol
end
(f::SQLFunctionName)(args...; kwargs...) = SQLFunction(f.name, args, kwargs)

struct Field <: SQLElement
    clause::Union{FromItem, SubQuery, Nothing}
    name::Symbol
end

struct SQLKeyword <: SQLElement
    name::Symbol
end

"""
    Octo.PlaceHolder
"""
struct PlaceHolder <: SQLElement
    body::String
end

const PredicateValueTypes = Union{Bool, Number, String, Symbol, Day, <:SQLElement, Type{PlaceHolder}}

struct Predicate <: SQLElement
    func::Function
    left::PredicateValueTypes
    right::PredicateValueTypes
end

struct SQLAlias <: SQLElement
    field::Union{Field, SQLFunction, Predicate}
    alias::Symbol
end

struct SQLExtract <: SQLElement
    field::Union{SQLKeyword, Type{DP}, Type{TP}}     where DP <: DatePeriod where TP <: TimePeriod
    from::Union{DateTime, DP, TP, CompoundPeriod} where DP <: DatePeriod where TP <: TimePeriod
end

"""
    Octo.Raw
"""
struct Raw <: SQLElement
    string::String
end

struct Enclosed <: SQLElement
    values::Vector
end

struct VectorOfTuples <: SQLElement
    values::Vector{<:Tuple}
end

struct KeywordAllKeyword <: SQLElement
    left::SQLKeyword
    right::SQLKeyword
end

# module Octo
