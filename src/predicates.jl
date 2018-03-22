# module Octo

import Base: ==, <, >, <=, >=

for op in (:(==), :(<), :(>), :(<=), :(>=))
    @eval begin
        ($op)(left::SQLElement, right::SQLElement) = Predicate(($op), left, right)
        ($op)(left::SQLElement, right::Union{Number, String}) = Predicate(($op), left, right)
        ($op)(left::Union{Number, String}, right::SQLElement) = Predicate(($op), left, right)
    end
end
