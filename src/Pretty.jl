module Pretty # Octo

const nrows_limit = 20

function _print_named_tuple_vector(io::IO, nts::Vector{<:NamedTuple})
    isempty(nts) && return
    uno = first(nts)
    real_nrows = length(nts)
    nrows = min(nrows_limit, real_nrows)
    ncols = length(uno)
    A = vcat(map(v -> vcat(v...), nts[1:nrows])...)
    rt = reshape(A, ncols, nrows)
    colnames = keys(uno)
    paddings = maximum((length ∘ string).(rt), dims=2)
    paddings = [maximum(x) for x in zip(paddings, (length ∘ string).(colnames))]
    padfuncs = (x -> x isa Number ? lpad : rpad).(values(uno))
    function pad(colidx, el)
        f = padfuncs[colidx]
        f(el, paddings[colidx])
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
    if real_nrows > nrows_limit
        printstyled(io, "\nFetched ")
        printstyled(io, real_nrows, color=:cyan)
        printstyled(io, " rows...")
    end
end

function Base.show(io::IO, mime::MIME"text/plain", nts::Vector{<:NamedTuple})
    _print_named_tuple_vector(io, nts)
end

end # module Octo.Pretty
