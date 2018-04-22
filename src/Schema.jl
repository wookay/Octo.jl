module Schema # Octo

tables = Dict{Core.TypeName,Dict{Symbol,Union{String,Tuple}}}()
validation_models = Dict{Core.TypeName,Function}()

function _model(M::Type; table_name::String, primary_key::Union{String,Tuple})
    Tname = Base.typename(M)
    dict = Dict(
        :table_name => table_name,
        :primary_key => primary_key
    )
    tables[Tname] = dict
    Pair(Tname, dict)
end

"""
    model(M::Type; table_name::String, kwargs...)
"""
function model(M::Type; table_name::String, kwargs...)
    primary_key = "id"
    if haskey(kwargs, :primary_key)
        primary_key = kwargs[:primary_key]
    elseif haskey(kwargs, :primary_keys)
        primary_key = kwargs[:primary_keys]
    end
    _model(M; table_name=table_name, primary_key=primary_key)
end

struct TableNameError <: Exception
    msg::String
end

struct PrimaryKeyError <: Exception
    msg::String
end

"""
    changeset(validations, M::Type)
"""
function changeset(validations, M::Type)
    Tname = Base.typename(M)
    validation_models[Tname] = validations
    Pair(Tname, validations)
end

include(joinpath("Schema", "validations.jl"))

end # module Octo.Schema
