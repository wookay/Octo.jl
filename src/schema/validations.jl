# module Octo.Schema

export InvalidChangesetError
export validate_length

struct InvalidChangesetError <: Exception
    msg
end

function validates(M, nt::NamedTuple)
    Tname = Base.typename(M)
    if haskey(validation_models, Tname)
        validations = validation_models[Tname]
        validations((M, nt))
    end
end

function validate_length((M, nt), field::Symbol; kwargs...)
    if haskey(nt, field)
        value = nt[field]
        check = (min= (value, num) -> length(value) >= num,)
        for (key, num) in kwargs
            if haskey(check, key)
                if check[key](value, num)
                else
                    throw(InvalidChangesetError(string(field, " length must be ", key, " = ", num)))
                end
            end
        end
    end
end

# end module Octo.Schema
