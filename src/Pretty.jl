"""
    Pretty

Tablize Vector{<:NamedTuple}
"""
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

"""
    Pretty.table(nts::Vector{<:NamedTuple})::String
"""
function table(nts::Vector{<:NamedTuple})::String
    buf = IOBuffer()
    show(buf, MIME"text/plain"(), nts)
    String(take!(buf))
end

"""
    Pretty.table(nt::NamedTuple)::String
"""
function table(nt::NamedTuple)::String
    buf = IOBuffer()
    show(buf, MIME"text/plain"(), nt)
    String(take!(buf))
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
    a = Char[]
    for (idx, x) in enumerate(s)
        n += textwidth(x)
        push!(a, x)
        if n > padding - 1
            break
        end
    end
    newstr = join(a)
    if length(s) == length(a) && padding > textwidth(newstr)
        news = newstr
        npad = padding - textwidth(newstr)
    else
        newdiff = textwidth(s) - textwidth(newstr)
        if padding < textwidth(newstr) || newdiff > 0 && length(a) >= 2
            newstr = join(a[1:end-2])
            newpad = padding - textwidth(newstr)
            news = string(newstr, fill('.', newpad)...)
        else
            news = newstr
        end
        npad = padding - textwidth(news)
    end
    string(news, npad > 0 ? join(fill(' ', npad)) : "")
end

function _print_named_tuple_vector(io::IO, nts::Vector{<:NamedTuple}; show_fetched_info::Bool=true)
    limit_nrows = settings[:nrows]
    limit_colsize = settings[:colsize]
    header_spike(tree, bold) = printstyled(io, tree, bold=bold)
    row_spike(tree, bold)    = printstyled(io, tree, bold=bold)
    colnames = fieldnames(first(typeof(nts).parameters))
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
    function fetched_info(io, real_nrows, limit_nrows)
        if iszero(real_nrows)
            printstyled(io, "empty", color=:cyan)
            printstyled(io, " row.")
        else
            printstyled(io, "\n")
            printstyled(io, real_nrows, color=:cyan)
            printstyled(io, " row", real_nrows == 1 ? "" : 's', '.',  real_nrows > limit_nrows ? ".." :  "")
        end
    end
    if isempty(nts)
        paddings = (length ∘ string).(colnames) .+ 2
        print_header((colidx, el) -> rpad(el, paddings[colidx]), paddings)
        fetched_info(io, real_nrows, limit_nrows)
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
    show_fetched_info && fetched_info(io, real_nrows, limit_nrows)
end

function Base.show(io::IO, mime::MIME"text/plain", nts::Vector{<:NamedTuple})
   if settings[:pretty]
       _print_named_tuple_vector(io, nts)
   else
       Base.show(io, nts)
   end
end

function Base.show(io::IO, mime::MIME"text/plain", nt::NamedTuple)
   if settings[:pretty]
       _print_named_tuple_vector(io, [nt]; show_fetched_info=false)
   else
       Base.show(io, nt)
   end
end

end # module Octo.Pretty
