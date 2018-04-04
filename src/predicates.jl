# module Octo

import Base: ==, <, >, <=, >=, -, +, *, /
const PlainTypes = Union{Number, String, Symbol, <:DatePeriod, <:TimePeriod}

for op in (:(==), :(<), :(>), :(<=), :(>=), :(-), :(+), :(*), :(/))
    @eval begin
        ($op)(left::SQLElement, right::SQLElement) = Predicate(($op), left, right)
        ($op)(left::SQLElement, right::PlainTypes) = Predicate(($op), left, right)
        ($op)(left::PlainTypes, right::SQLElement) = Predicate(($op), left, right)
        ($op)(left::SQLElement, right::Type{PlaceHolder}) = Predicate(($op), left, right)
    end
end

function Base.:*(left::Keyword, right::Keyword)
    KeywordAllKeyword(left, right)
end

# module Octo
