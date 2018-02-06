module Schema

tables = Dict{TypeName,String}()

function model(M::Type; table_name::String)
    tables[Base.typename(M)] = table_name
end

struct TableNameError <: Exception
    msg::String
end

end # module Octo.Schema
