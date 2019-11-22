module Repo # Octo

using ..DBMS
using ..Backends
using ..AdapterBase
using ..Queryable: Structured, SubQuery, FromItem
using ..Octo: Raw, SQLKeyword
using ..Schema # Schema.validates
using ..Pretty: show

struct NeedsConnectError <: Exception
    msg
end

const ExecuteResult = NamedTuple

@enum RepoLogLevel::Int32 begin
    LogLevelDebugSQL = -1
    LogLevelInfo = 0
end

const current = Dict{Symbol, Union{Nothing, Module, RepoLogLevel}}(
    :adapter => nothing,
    :loader => nothing,
    :log_level => LogLevelInfo
)

const color_params = :yellow

current_loader() = current[:loader]
function current_adapter() # throw Repo.NeedsConnectError
    if current[:adapter] isa Nothing
        throw(NeedsConnectError("Needs to Repo.connect"))
    else
        current[:adapter]
    end
end

function set_log_level(level::RepoLogLevel)
    current[:log_level] = level
end

"""
    Repo.debug_sql(debug::Bool = true)
"""
function debug_sql(debug::Bool = true)
    current[:log_level] = debug ? LogLevelDebugSQL : LogLevelInfo
end

function print_debug_sql_params(io, params)
    printstyled(io, "   ")
    for (idx, x) in enumerate(params)
        printstyled(io, repr(x), color=color_params)
        length(params) != idx && printstyled(io, ", ")
    end
end

function print_debug_sql(stmt::Structured, params = nothing)
    if current[:log_level] <= LogLevelDebugSQL
        buf = IOBuffer()
        show(IOContext(buf, :color=>true), MIME"text/plain"(), stmt)
        !(params isa Nothing) && print_debug_sql_params(IOContext(buf, :color=>true), params)
        @info String(take!(buf))
    end
end

# Repo.connect
"""
    Repo.connect(; adapter::Module, database::Union{Nothing,Type{D} where {D <: DBMS.AbstractDatabase}}=nothing, kwargs...)
"""
function connect(; adapter::Module, database::Union{Nothing,Type{D} where {D <: DBMS.AbstractDatabase}}=nothing, kwargs...)
    if database !== nothing
        adapter.Database[:ID] = database
    end
    AdapterBase.current[:database] = adapter.DatabaseID()

    current[:adapter] = adapter
    loader = Backends.backend(adapter)
    current[:loader] = loader

    Base.invokelatest(loader.db_connect; kwargs...)
end

# Repo.disconnect
"""
    Repo.disconnect()
"""
function disconnect()
    loader = current_loader()
    disconnected = loader.db_disconnect()
    current[:adapter] = nothing
    current[:loader] = nothing
    disconnected
end

function get_primary_key(M)::Union{Nothing,Symbol,Vector}
    Tname = Base.typename(M)
    tbl = Schema.tables[Tname]
    if haskey(tbl, :primary_key)
        pk = getindex(tbl, :primary_key)
        if pk isa String
            Symbol(pk)
        elseif pk isa Tuple
            collect(pk)
        else
            pk
        end
    else
        nothing
    end
end

function _field_for_primary_key(M) # throw Schema.PrimaryKeyError
    primary_key = get_primary_key(M)
    if primary_key === nothing
        throw(Schema.PrimaryKeyError(""))
    else
        a = current_adapter()
        table = a.from(M)
        a.Field(table, primary_key)
    end
end

function _field_for_primary_key(M, nt::NamedTuple) # throw Schema.PrimaryKeyError
    primary_key = get_primary_key(M)
    if primary_key === nothing
        throw(Schema.PrimaryKeyError(""))
    else
        key = _field_for_primary_key(M)
        pk = getfield(nt, primary_key)
        (key, pk)
    end
end


# Repo.query

"""
    Repo.query(stmt::Structured)
"""
function query(stmt::Structured)
    a = current_adapter()
    sql = a.to_sql(stmt)
    print_debug_sql(stmt)
    loader = current_loader()
    loader.query(sql)
end

"""
    Repo.query(M::Type)
"""
function query(M::Type)
    a = current_adapter()
    table = a.from(M)
    query([a.SELECT * a.FROM table])
end

"""
    Repo.query(from::FromItem)
"""
function query(from::FromItem)
    query(from.__octo_model)
end

"""
    Repo.query(subquery::SubQuery)
"""
function query(subquery::SubQuery)
    query(subquery.__octo_query)
end

"""
    Repo.query(rawquery::Octo.Raw)
"""
function query(rawquery::Raw)
    query([rawquery])
end

### Repo.query - vals::Vector
"""
    Repo.query(stmt::Structured, vals::Vector)
"""
function query(stmt::Structured, vals::Vector) # throw Backends.UnsupportedError
    a = current_adapter()
    prepared = a.to_sql(stmt)
    print_debug_sql(stmt, vals)
    loader = current_loader()
    loader.query(prepared, vals)
end

### Repo.query - pk
"""
    Repo.query(M::Type, pk::Union{Int, String})
"""
function query(M::Type, pk::Union{Int, String}) # throw Schema.PrimaryKeyError
    a = current_adapter()
    table = a.from(M)
    key = _field_for_primary_key(M)
    query([a.SELECT * a.FROM table a.WHERE key == pk])
end

"""
    Repo.query(from::FromItem, pk::Union{Int, String})
"""
function query(from::FromItem, pk::Union{Int, String}) # throw Schema.PrimaryKeyError
    query(from.__octo_model, pk)
end

### Repo.query - pk_range
"""
    Repo.query(M::Type, pk_range::UnitRange{Int64})
"""
function query(M::Type, pk_range::UnitRange{Int64}) # throw Schema.PrimaryKeyError
    a = current_adapter()
    table = a.from(M)
    key = _field_for_primary_key(M)
    query([a.SELECT * a.FROM table a.WHERE key a.BETWEEN pk_range.start a.AND pk_range.stop])
end

"""
    Repo.query(from::FromItem, pk_range::UnitRange{Int64}
"""
function query(from::FromItem, pk_range::UnitRange{Int64}) # throw Schema.PrimaryKeyError
    query(from.__octo_model, pk_range)
end

### Repo.query - nt::NamedTuple
"""
    Repo.query(stmt::Structured, nt::NamedTuple)
"""
function query(stmt::Structured, nt::NamedTuple)
    a = current_adapter()
    v = vec(stmt)
    for (idx, kv) in enumerate(pairs(nt))
        key = a.Field(nothing, kv.first)
        push!(v, key == kv.second)
        idx != length(nt) && push!(v, a.AND)
    end
    query(v)
end

"""
    Repo.query(M::Type, nt::NamedTuple)
"""
function query(M::Type, nt::NamedTuple)
    a = current_adapter()
    table = a.from(M)
    v = [a.SELECT, *, a.FROM, table, a.WHERE]
    for (idx, kv) in enumerate(pairs(nt))
        key = Base.getproperty(table, kv.first)
        push!(v, key == kv.second)
        idx != length(nt) && push!(v, a.AND)
    end
    query(v)
end

"""
    Repo.query(from::FromItem, nt::NamedTuple)
"""
function query(from::FromItem, nt::NamedTuple)
    query(from.__octo_model, nt)
end

"""
    Repo.query(subquery::SubQuery, nt::NamedTuple)
"""
function query(subquery::SubQuery, nt::NamedTuple)
    query(subquery.__octo_query, nt)
end

"""
    Repo.query(rawquery::Octo.Raw, nt::NamedTuple)
"""
function query(rawquery::Raw, nt::NamedTuple)
    query([rawquery], nt)
end


# Repo.get
"""
    Repo.get(M::Type, pk::Union{Int, String})
"""
function get(M::Type, pk::Union{Int, String}) # throw Schema.PrimaryKeyError
    query(M, pk)
end

"""
    Repo.get(M::Type, pk_range::UnitRange{Int64})
"""
function get(M::Type, pk_range::UnitRange{Int64}) # throw Schema.PrimaryKeyError
    query(M, pk_range)
end

"""
    Repo.get(M::Type, nt::NamedTuple)
"""
function get(M::Type, nt::NamedTuple)
    query(M, nt)
end


# Repo.execute
"""
    Repo.execute(stmt::Structured)
"""
function execute(stmt::Structured)
    a = current_adapter()
    sql = a.to_sql(stmt)
    print_debug_sql(stmt)
    loader = current_loader()
    loader.execute(sql)
end

"""
    Repo.execute(stmt::Structured, vals::Vector)
"""
function execute(stmt::Structured, vals::Vector)
    a = current_adapter()
    prepared = a.to_sql(stmt)
    print_debug_sql(stmt, vals)
    loader = current_loader()
    loader.execute(prepared, vals)
end

"""
    Repo.execute(stmt::Structured, nts::Vector{<:NamedTuple})
"""
function execute(stmt::Structured, nts::Vector{<:NamedTuple})
    a = current_adapter()
    prepared = a.to_sql(stmt)
    print_debug_sql(stmt, nts)
    loader = current_loader()
    loader.execute(prepared, nts)
end

execute(raw::AdapterBase.Raw)                            = execute([raw])
execute(raw::AdapterBase.Raw, nt::NamedTuple)            = execute([raw], [nt])
execute(raw::AdapterBase.Raw, nts::Vector{<:NamedTuple}) = execute([raw], nts)
execute(raw::AdapterBase.Raw, vals::Vector)              = execute([raw], vals)


# Repo.insert!

function do_insert(block, a, returning::Union{Nothing,Symbol,Vector})
    extra = []
    if a.DatabaseID === DBMS.PostgreSQL && returning !== nothing
        extra = vcat(a.RETURNING, returning isa Symbol ? returning : tuple(Symbol.(returning)...))
    end
    result = block(extra)
    if a.DatabaseID === DBMS.PostgreSQL
        result
    else
        execute_result(a.INSERT)
    end
end

"""
    Repo.insert!(M::Type, nts::Vector{<:NamedTuple}; returning::Union{Nothing,Symbol,Vector}=[:id])
"""
function insert!(M::Type, nts::Vector{<:NamedTuple}; returning::Union{Nothing,Symbol,Vector}=get_primary_key(M))
    if !isempty(nts)
        Schema.validates.(M, nts) # throw InvalidChangesetError
        a = current_adapter()
        table = a.from(M)
        nt = first(nts)
        fieldnames = a.Enclosed(collect(keys(nt)))
        values = a.placeholders(length(nt))
        do_insert(a, returning) do extra
            execute([a.INSERT a.INTO table fieldnames a.VALUES values extra...], nts)
        end
    else
        nothing
    end
end

"""
    Repo.insert!(M::Type, vals::Vector{<:Tuple}; returning::Union{Nothing,Symbol,Vector}=[:id])
"""
function insert!(M::Type, vals::Vector{<:Tuple}; returning::Union{Nothing,Symbol,Vector}=get_primary_key(M))
    if !isempty(vals)
        a = current_adapter()
        table = a.from(M)
        do_insert(a, returning) do extra
            execute([a.INSERT a.INTO table a.VALUES a.VectorOfTuples(vals) extra...])
        end
    else
        nothing
    end
end

"""
    Repo.insert!(M, nt::NamedTuple; returning::Union{Noting,Symbol,Vector}=[:id])
"""
function insert!(M, nt::NamedTuple; kwargs...)
    insert!(M, [nt]; kwargs...)
end


# Repo.execute_result

function execute_result(command::SQLKeyword)::ExecuteResult
    loader = current_loader()
    loader.execute_result(command)
end


# Repo.update!
"""
    Repo.update!(M::Type, nt::NamedTuple)
"""
function update!(M::Type, nt::NamedTuple) # throw Schema.PrimaryKeyError
    Schema.validates(M, nt) # throw InvalidChangesetError
    a = current_adapter()
    (key, pk) = _field_for_primary_key(M, nt)
    table = a.from(M)
    rest = filter(kv -> kv.first != key.name, pairs(nt))
    v = Any[a.UPDATE, table, a.SET]

    # tup[1] : idx
    # tup[2] : kv
    push!(v, tuple(map(tup -> a.Field(table, tup[2].first) == a.placeholder(tup[1]), enumerate(rest))...))

    push!(v, a.WHERE)
    push!(v, key == pk)
    execute(v, collect(values(rest)))
    nothing
end


# Repo.delete!
"""
    Repo.delete!(M::Type, nt::NamedTuple)
"""
function delete!(M::Type, nt::NamedTuple) # throw Schema.PrimaryKeyError
    a = current_adapter()
    (key, pk) = _field_for_primary_key(M, nt)
    table = a.from(M)
    execute([a.DELETE a.FROM table a.WHERE key == pk])
    nothing
end

"""
    Repo.delete!(M::Type, pk_range::UnitRange{Int64})
"""
function delete!(M::Type, pk_range::UnitRange{Int64}) # throw Schema.PrimaryKeyError
    a = current_adapter()
    table = a.from(M)
    key = _field_for_primary_key(M)
    execute([a.DELETE a.FROM table a.WHERE key a.BETWEEN pk_range.start a.AND pk_range.stop])
    nothing
end

end # module Octo.Repo
