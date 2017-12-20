struct Predicate
    f::Function
    field1::Union{Bool, Number, String, Field, Predicate, SqlFunc, Void}
    field2::Union{Bool, Number, String, Field, Predicate, SqlFunc}
end
