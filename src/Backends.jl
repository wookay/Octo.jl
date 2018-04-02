module Backends # Octo

struct UnsupportedError <: Exception
    msg
end

function backend(adapter::Module) # UnsupportedError
    sym = nameof(adapter)
    L = Symbol(sym, :Loader)
    mod = Main
    if isdefined(mod, L)
        getfield(mod, L)
    else
        try
            path = normpath(@__DIR__, "Backends", string(sym, ".jl"))
            mod.include(path)
        catch err
            throw(UnsupportedError(string("error on ", adapter)))
        end
    end
end

end # module Octo.Backends
