module Repo

import ..Backends
import ..AdapterBase
import ..Queryable: Structured
import ..Schema

@enum RepoLogLevel::Int32 begin
    LogLevelDebugSQL = -1
    LogLevelInfo = 0
end

const current = Dict{Symbol, Union{Nothing, Module, RepoLogLevel}}(
    :loader => nothing,
    :adapter => nothing,
    :log_level => LogLevelInfo
)

current_loader() = current[:loader]
current_adapter() = current[:adapter]

function debug_sql_params(io, params)
    printstyled(io, "   ")
    for (idx, x) in enumerate(params)
        printstyled(io, x, color=:green)
        length(params) != idx && printstyled(io, ", ")
    end
end

function debug_sql(stmt::Structured, params = nothing)
    if current[:log_level] <= LogLevelDebugSQL
        buf = IOBuffer()
        show(IOContext(buf, :color=>true), MIME"text/plain"(), stmt)
        !(params isa Nothing) && debug_sql_params(IOContext(buf, :color=>true), params)
        @info String(take!(buf))
    end
end

# Repo.set_log_level
function set_log_level(level::RepoLogLevel)
    current[:log_level] = level
end

# Repo.config
function config(; adapter::Module, kwargs...)
    sym = nameof(adapter)
    DatabaseID = getfield(AdapterBase.Database, Symbol(sym, :Database))
    AdapterBase.current[:database] = DatabaseID()

    current[:adapter] = adapter
    loader = Backends.backend(adapter)
    current[:loader] = loader

    if haskey(kwargs, :sink)
        Base.invokelatest(loader.sink, kwargs[:sink])
    end
    args = (:sink,)
    options = filter(kv -> !(kv.first in args), kwargs)

    Base.invokelatest(loader.load; options...)
end

# Repo.disconnect
function disconnect()
    loader = current_loader()
    loader.disconnect()
end

# Repo.query
function query(stmt::Structured)
    a = current_adapter()
    sql = a.to_sql(stmt)
    debug_sql(stmt)
    loader = current_loader()
    loader.query(sql)
end

# Repo.execute
function execute(stmt::Structured)
    a = current_adapter()
    sql = a.to_sql(stmt)
    debug_sql(stmt)
    loader = current_loader()
    loader.execute(sql)
end

function execute(stmt::Structured, vals::Vector)
    a = current_adapter()
    sql = a.to_sql(stmt)
    debug_sql(stmt, vals)
    loader = current_loader()
    loader.execute(sql, vals)
end

function execute(stmt::Structured, nts::Vector{<:NamedTuple})
    a = current_adapter()
    sql = a.to_sql(stmt)
    debug_sql(stmt, nts)
    loader = current_loader()
    loader.execute(sql, nts)
end

execute(raw::AdapterBase.Raw) = execute([raw])
execute(raw::AdapterBase.Raw, nt::NamedTuple) = execute([raw], [nt])
execute(raw::AdapterBase.Raw, nts::Vector{<:NamedTuple}) = execute([raw], nts)
execute(raw::AdapterBase.Raw, vals::Vector) = execute([raw], vals)

# Repo.all
function all(M)
    a = current_adapter()
    table = a.from(M)
    query([a.SELECT * a.FROM table])
end

function _get_primary_key(M) # throws Schema.PrimaryKeyError
    Tname = Base.typename(M)
    info = Schema.tables[Tname]
    if haskey(info, :primary_key)
        a = current_adapter()
        table = a.from(M)
        primary_key = Symbol(info[:primary_key])
        a.Field(table, primary_key)
    else
        throws(Schema.PrimaryKeyError(""))
    end
end

function _get_primary_key_with(M, nt::NamedTuple) # throws Schema.PrimaryKeyError
    Tname = Base.typename(M)
    info = Schema.tables[Tname]
    if haskey(info, :primary_key)
        key = _get_primary_key(M)
        primary_key = Symbol(info[:primary_key])
        pk = getfield(nt, primary_key)
        (key, pk)
     else
        throws(Schema.PrimaryKeyError(""))
    end
end

# Repo.get
function get(M, pk::Union{Int, String}) # throws Schema.PrimaryKeyError
    a = current_adapter()
    table = a.from(M)
    key = _get_primary_key(M)
    query([a.SELECT * a.FROM table a.WHERE key == pk])
end

function get(M, nt::NamedTuple)
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

# Repo.insert!
function insert!(M, nts::Vector{<:NamedTuple})
    if !isempty(nts)
        a = current_adapter()
        table = a.from(M)
        nt = first(nts)
        fieldnames = a.Enclosed(collect(keys(nt)))
        execute([a.INSERT a.INTO table fieldnames a.VALUES a.placeholders(length(nt))], nts)
   end
end

function insert!(M, nt::NamedTuple)
    insert!(M, [nt])
end

# Repo.update!
function update!(M, nt::NamedTuple) # throws Schema.PrimaryKeyError
    (key, pk) = _get_primary_key_with(M, nt)
    a = current_adapter()
    table = a.from(M)
    rest = filter(kv -> kv.first != key.name, pairs(nt))
    v = Any[a.UPDATE, table, a.SET]
    push!(v, tuple(map(tup -> a.Field(table, tup[2].first) == a.placeholder(tup[1]), enumerate(rest))...))
    push!(v, a.WHERE)
    push!(v, key == pk)
    execute(v, collect(values(rest)))
end

# Repo.delete!
function delete!(M, nt::NamedTuple) # throws Schema.PrimaryKeyError
    (key, pk) = _get_primary_key_with(M, nt)
    a = current_adapter()
    table = a.from(M)
    execute([a.DELETE a.FROM table a.WHERE key == pk])
end

end # module Octo.Repo
