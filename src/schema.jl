module Schema

tables = Dict{Core.TypeName,Dict{Symbol,String}}()
validation_models = Dict{Core.TypeName,Function}()

"""
    model(M::Type; table_name::String, primary_key::String="id")
"""
function model(M::Type; table_name::String, primary_key::String="id")
    Tname = Base.typename(M)
    dict = Dict(
        :table_name => table_name,
        :primary_key => primary_key
    )
    tables[Tname] = dict
    Pair(Tname, dict)
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

include("schema/validations.jl")

end # module Octo.Schema
