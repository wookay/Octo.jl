# module Octo

import Base: ==, <, >, <=, >=

==(f1::Field, f2::Field)          = Predicate(==, f1, f2)
==(f1::Field, val::Number)        = Predicate(==, f1, val)
==(f1::Field, val::String)        = Predicate(==, f1, val)

<(lhs::Union{Field}, rhs::Union{Number,Field}) = Predicate(<, lhs, rhs)
<(lhs::Union{Number, Field}, rhs::Union{Field}) = Predicate(<, lhs, rhs)

>(lhs::Union{Field}, rhs::Union{Number,Field}) = Predicate(>, lhs, rhs)
>(lhs::Union{Number, Field}, rhs::Union{Field}) = Predicate(>, lhs, rhs)

<=(lhs::Union{Field}, rhs::Union{Number,Field}) = Predicate(<=, lhs, rhs)
<=(lhs::Union{Number, Field}, rhs::Union{Field}) = Predicate(<=, lhs, rhs)

>=(lhs::Union{Field}, rhs::Union{Number,Field}) = Predicate(>=, lhs, rhs)
>=(lhs::Union{Number, Field}, rhs::Union{Field}) = Predicate(>=, lhs, rhs)
