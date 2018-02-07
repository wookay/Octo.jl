# module Octo

import Base: ==, <, >, <=, >=

for op in (:(==), :(<), :(>), :(<=), :(>=))
    @eval begin
        ($op)(left::Field, right::Field) = Predicate(($op), left, right)
        ($op)(left::Union{Field, AggregateFunction}, right::Union{Number, String}) = Predicate(($op), left, right)
        ($op)(left::Union{Number, String}, right::Union{Field, AggregateFunction}) = Predicate(($op), left, right)
    end
end
