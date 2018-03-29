module Pretty # Octo

settings = Dict{Symbol, Any}(
    :pretty => true,
    :nrows => 20,
    :colsize => 30,
)

const pretty_settings_keys = (:nrows, :colsize)

"""
    Pretty.set(pretty::Bool=true; kwargs...)

Set the display options for `Vector{<:NamedTuple}` rows.

```julia-repl
julia> Pretty.set(nrows = 10)     # limit number of the rows

julia> Pretty.set(colsize = 10)   # limit column size

julia> Pretty.set(false)          # do or don't use pretty

```
"""
function set(pretty::Bool=true; kwargs...)
    for (k, v) in kwargs
        if k in pretty_settings_keys && v isa Int && v > 0
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
    limit_nrows = settings[:nrows]
    limit_colsize = settings[:colsize]
    header_spike(tree, bold) = printstyled(io, tree, bold=bold)
    row_spike(tree, bold)    = printstyled(io, tree, bold=bold)
    colnames = collect(first(typeof(nts).parameters).names)
    ncols = length(colnames)
    real_nrows = length(nts)
    function print_header(pad_, paddings_)
        (boldone, boldtwo) = (false, false)
        header_spike("| ", boldone)
        for colidx in 1:ncols
            printstyled(io, pad_(colidx, colnames[colidx]), color=:cyan)
            ncols != colidx && header_spike(" | ", boldone)
        end
        header_spike(" |\n", boldone)
        header_spike("| ", boldtwo)
        for colidx in 1:ncols
            header_spike(join(fill('-', paddings_[colidx])), boldtwo)
            ncols != colidx && header_spike(" | ", boldtwo)
        end
        header_spike(" |\n", boldtwo)
    end
    function fetched_info()
        printstyled(io, "\n")
        printstyled(io, real_nrows, color=:cyan)
        printstyled(io, " row", real_nrows == 1 ? "" : 's', '.',  real_nrows > limit_nrows ? ".." :  "")
    end
    if isempty(nts)
        paddings = (length ∘ string).(colnames) .+ 2
        print_header((colidx, el) -> rpad(el, paddings[colidx]), paddings)
        fetched_info()
        return
    end
    uno = first(nts)
    nrows = min(limit_nrows, real_nrows)
    A = vcat(map(v -> vcat(v...), nts[1:nrows])...)
    rt = reshape(A, ncols, nrows)
    paddings = maximum((length ∘ string).(rt), dims=2)
    paddings = [maximum(x) for x in zip(paddings, (length ∘ string).(colnames))] .+ 2
    for (colidx, el) in enumerate(values(uno))
        if el isa String
            paddings[colidx] = min(max(limit_colsize, (length ∘ string)(colnames[colidx])), paddings[colidx])
        end
    end
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
    print_header(pad, paddings)
    for rowidx in 1:nrows
        row = nts[rowidx]
        bold = isodd(rowidx)
        row_spike("| ", bold)
        for (colidx, el) in enumerate(values(row))
            print(io, pad(colidx, el))
            ncols != colidx && row_spike(" | ", false)
        end
        row_spike(" |", false)
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
