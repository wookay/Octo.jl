abstract type Model end

struct Field
    table
    fieldname
end

modelstore = Dict()

function Base.setproperty!(::Type{M}, propname::Symbol, value) where M <: Model
    typ = Base.typename(M)
    modelstore[typ] = Dict(propname => value)
end

function Base.getproperty(::M, propname::Symbol) where M <: Model
    Field(M, propname)
end
