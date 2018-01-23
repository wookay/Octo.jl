# module Octo

import Base: ==, <, >, <=, >=

for op in (:(==), :(<), :(>), :(<=), :(>=))
    @eval begin
        ($op)(left::Field, right::Union{Field, Number, String}) = Predicate(($op), left, right)
        ($op)(left::Union{Field, Number, String}, right::Field) = Predicate(($op), left, right)
    end
end
