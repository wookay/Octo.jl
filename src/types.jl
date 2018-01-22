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
    field1::Union{Bool, Number, String, Field, Predicate, Nothing}
    field2::Union{Bool, Number, String, Field, Predicate}
end
