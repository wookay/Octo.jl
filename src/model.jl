abstract type Model end

struct Field
    name
end

modelstore = Dict()

function Base.setproperty!(::Type{M}, name::Symbol, value) where M <: Model
    modelstore[name] = value
end

function Base.getproperty(::Type{M}, name::Symbol) where M <: Model
    modelstore[name]
end

function Base.getproperty(::M, name::Symbol) where M <: Model
    Field(name)
end
