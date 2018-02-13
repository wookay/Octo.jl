module Backends

function backend(adapter::Module)
    sym = nameof(adapter)
    L = Symbol(sym, :Loader)
    if !isdefined(Backends, L)
        try
            path = normpath(dirname(@__FILE__), "backends", string(sym, ".jl"))
            Backends.include(path)
        catch err
            error(err)
        end
    end
end

end # module Octo.Backends
