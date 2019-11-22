module Schema # Octo

tables = Dict{Core.TypeName,Dict{Symbol,Union{String,Symbol,Vector{Symbol}}}}()
validation_models = Dict{Core.TypeName,Function}()

function _model(M::Type; table_name::String, primary_key::Union{Nothing,Symbol,Vector{Symbol}})
    Tname = Base.typename(M)
    dict = Dict{Symbol,Union{String,Symbol,Vector{Symbol}}}(
        :table_name => table_name,
    )
    if primary_key !== nothing
        dict[:primary_key] = primary_key
    end
    tables[Tname] = dict
    Pair(Tname, dict)
end

"""
    model(M::Type; table_name::String, primary_key::Union{Nothing,Symbol,String,Vector,Tuple}="id")
"""
function model(M::Type; table_name::String, primary_key::Union{Nothing,Symbol,String,Vector,Tuple}="id")
    if primary_key isa Vector{String}
        pk = Symbol.(primary_key)
    elseif primary_key isa String
        pk = Symbol(primary_key)
    elseif primary_key isa Tuple # legacy
        pk = collect(Symbol.(primary_key))
    else
        pk = primary_key
    end
    _model(M; table_name=table_name, primary_key=pk)
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
