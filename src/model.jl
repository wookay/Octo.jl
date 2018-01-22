# module Octo

function Base.getproperty(::Type{M}, field::Symbol) where M <: Model
    if :schema == field
        function (; kwargs...)
            Schema.tables[Base.typename(M)] = kwargs[:table_name]
        end
    else
        getfield(M, field)
    end
end
