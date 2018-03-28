module Pretty # Octo

settings = Dict{Symbol, Any}(
    :pretty => true,
    :nrows => 20,
    :colsize => 30,
)

const pretty_settings_keys = (:nrows, :colsize)

"""
    Pretty.set(pretty::Bool=true; kwargs...)

Set the display options for the fetch rows.

```julia-repl
julia> Pretty.set(nrows = 10)     # limit number of rows

julia> Pretty.set(colsize = 10)   # limit column size

julia> Pretty.set(false)          # do or don't use pretty

```
"""
function set(pretty::Bool=true; kwargs...)
    for (k, v) in kwargs
        if k in pretty_settings_keys
            settings[k] = v
        end
    end
    settings[:pretty] = pretty
    settings
end

function _regularize_text(str::String, padding::Int)::String
    s = escape_string(str)
    if textwidth(s) < padding
        padded_str = rpad(s, padding)
        if textwidth(padded_str) > padding
        else
            return padded_str
        end
    end
    n = 0
    a = []
    for (idx, x) in enumerate(s)
        n += textwidth(x)
        if n > padding - 2
            break
        end
        push!(a, x)
    end
    newstr = join(a)
    newpad = padding - textwidth(newstr)
    if newpad >= 2
        news = string(newstr, "..")
    elseif newpad == 1
        news = string(newstr, ".")
    else
        news = newstr
    end
    npad = padding - textwidth(news)
    string(news, npad > 0 ? join(fill(' ', npad)) : "")
end

function _print_named_tuple_vector(io::IO, nts::Vector{<:NamedTuple})
    real_nrows = length(nts)
    function fetched_info()
        printstyled(io, "\nFetched ")
        printstyled(io, real_nrows, color=:cyan)
        printstyled(io, " rows.", real_nrows > 1 ? ".." : "")
    end
    if isempty(nts)
        fetched_info()
        return
    end
    uno = first(nts)
    limit_nrows = settings[:nrows]
    limit_colsize = settings[:colsize]
    nrows = min(limit_nrows, real_nrows)
    ncols = length(uno)
    A = vcat(map(v -> vcat(v...), nts[1:nrows])...)
    rt = reshape(A, ncols, nrows)
    colnames = keys(uno)
    paddings = maximum((length ∘ string).(rt), dims=2)
    paddings = [maximum(x) for x in zip(paddings, (length ∘ string).(colnames))] .+ 2
    paddings = [minimum(x) for x in zip(paddings, fill(limit_colsize, ncols))]
    padfuncs = (x -> x isa Number ? lpad : rpad).(values(uno))
    function pad(colidx, el)
        f = padfuncs[colidx]
        padding = paddings[colidx]
        if el isa String
            _regularize_text(el, padding)
        else
            f(el, padding)
        end
    end
    header_spike(tree) = printstyled(io, tree, bold=false)
    row_spike(tree)    = printstyled(io, tree, bold=false)
    header_spike("| ")
    for colidx in 1:ncols
        printstyled(io, pad(colidx, colnames[colidx]), color=:cyan)
        ncols != colidx && header_spike(" | ")
    end
    header_spike(" |\n")
    header_spike("| ")
    for colidx in 1:ncols
        header_spike(join(fill('-', paddings[colidx])))
        ncols != colidx && header_spike(" | ")
    end
    header_spike(" |\n")
    for rowidx in 1:nrows
        row = nts[rowidx]
        row_spike("| ")
        for (colidx, el) in enumerate(values(row))
            print(io, pad(colidx, el))
            ncols != colidx && row_spike(" | ")
        end
        row_spike(" |")
        nrows != rowidx && println(io)
    end
    fetched_info()
end

function Base.show(io::IO, mime::MIME"text/plain", nts::Vector{<:NamedTuple})
   if settings[:pretty]
       _print_named_tuple_vector(io, nts)
   else
       Base.show(io, nts)
   end
end

end # module Octo.Pretty
