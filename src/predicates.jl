# module Octo

import Base: ==, <, >, <=, >=

for op in (:(==), :(<), :(>), :(<=), :(>=))
    @eval begin
        ($op)(left::Union{Field, AggregateFunction}, right::Union{Field, Number, String}) = Predicate(($op), left, right)
        ($op)(left::Union{Field, Number, String}, right::Union{Field, AggregateFunction}) = Predicate(($op), left, right)
    end
end
