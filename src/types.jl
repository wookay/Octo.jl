# module Octo

abstract type Model end

struct FromClause
    __octo_model
    __octo_as
end

struct SchemaError <: Exception
    msg::String
end

struct Field
    clause::FromClause
    name::Symbol
end

struct Predicate
    func::Function
    left::Union{Bool, Number, String, Field, Predicate}
    right::Union{Bool, Number, String, Field, Predicate}
end
