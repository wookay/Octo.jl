module Backends

struct UnsupportedError <: Exception
    msg
end

function backend(adapter::Module)
    sym = nameof(adapter)
    L = Symbol(sym, :Loader)
    mod = Main
    if isdefined(mod, L)
        getfield(mod, L)
    else
        try
            path = normpath(dirname(@__FILE__), "backends", string(sym, ".jl"))
            mod.include(path)
        catch err
            error(err)
        end
    end
end

end # module Octo.Backends
