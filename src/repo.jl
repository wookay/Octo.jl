module Repo

import ..Backends
import ..AdapterBase
import ..Queryable: Structured
import ..Schema

const current = Dict{Symbol, Union{Nothing, Module, Bool}}(
    :loader => nothing,
    :adapter => nothing,
    :debug_sql => false
)

current_loader() = current[:loader]
current_adapter() = current[:adapter]

function debug_sql(stmt::Structured) 
    if current[:debug_sql]
        buf = IOBuffer()
        show(IOContext(buf, :color=>true), MIME"text/plain"(), stmt)
        @info String(take!(buf))
    end
end

# Repo.config
function config(; adapter::Module, kwargs...)
    sym = nameof(adapter)
    DatabaseID = getfield(AdapterBase.Database, Symbol(sym, :Database))
    AdapterBase.current[:database] = DatabaseID()

    current[:adapter] = adapter
    loader = Backends.backend(adapter)
    current[:loader] = loader

    haskey(kwargs, :debug_sql) && setindex!(current, kwargs[:debug_sql], :debug_sql)
    excepts = (:debug_sql,)
    kwargs_excepts = filter(kv -> !(kv.first in excepts), kwargs)
    Base.invokelatest(loader.load; kwargs_excepts...)
end

# Repo.disconnect
function disconnect()
    loader = current_loader()
    loader.disconnect()
end

# Repo.execute
function execute(stmt::Structured)
    a = current_adapter()
    sql = a.to_sql(stmt)
    debug_sql(stmt)
    loader = current_loader()
    loader.execute(sql)
end

function execute(stmt::Structured, nts::Vector) # Vector{NamedTuple}
    a = current_adapter()
    sql = a.to_sql(stmt)
    debug_sql(stmt)
    loader = current_loader()
    loader.execute(sql, Vector{Tuple}(values.(nts)))
end

function execute(stmt::Structured, nt::NamedTuple)
    loader.execute(stmt, [nt])
end

function execute(raw::AdapterBase.Raw)
    execute([raw])
end

function execute(raw::AdapterBase.Raw, nts::Vector) # Vector{NamedTuple}
    execute([raw], nts)
end

function execute(raw::AdapterBase.Raw, nt::NamedTuple)
    execute(raw, [nt])
end

# Repo.query
function query(stmt::Structured)
    a = current_adapter()
    sql = a.to_sql(stmt)
    debug_sql(stmt)
    loader = current_loader()
    loader.query(sql)
end

# Repo.all
function all(M)
    a = current_adapter()
    table = a.from(M)
    query([a.SELECT * a.FROM table])
end

# _get_primary_key
function _get_primary_key(M) # throws Schema.PrimaryKeyError
    Tname = Base.typename(M)
    info = Schema.tables[Tname]
    if haskey(info, :primary_key)
        a = current_adapter()
        table = a.from(M)
        Base.getproperty(table, Symbol(info[:primary_key]))
    else
        throws(Schema.PrimaryKeyError(""))
    end
end

function _get_primary_key(M, nt::NamedTuple) # throws Schema.PrimaryKeyError
    Tname = Base.typename(M)
    info = Schema.tables[Tname]
    if haskey(info, :primary_key)
        a = current_adapter()
        table = a.from(M)
        primary_key = Symbol(info[:primary_key])
        key = Base.getproperty(table, primary_key)
        pk = getfield(nt, primary_key)
        (key, pk)
    else
        throws(Schema.PrimaryKeyError(""))
    end
end

# Repo.get
function get(M, pk::Union{Int, String}) # throws Schema.PrimaryKeyError
    key = _get_primary_key(M)
    a = current_adapter()
    table = a.from(M)
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
function insert!(M, nts::Vector) # Vector{NamedTuple}
    if !isempty(nts)
        a = current_adapter()
        table = a.from(M)
        nt = first(nts)
        fieldnames = a.Enclosed(keys(nt))
        execute([a.INSERT a.INTO table fieldnames a.VALUES a.paramholders(nt)], nts)
   end
end

function insert!(M, nt::NamedTuple)
    insert!(M, [nt])
end

# Repo.update!
function update!(M, nt::NamedTuple) # throws Schema.PrimaryKeyError
    (key, pk) = _get_primary_key(M, nt)
    a = current_adapter()
    table = a.from(M)
    vals = (; filter(kv -> kv.first != key, collect(pairs(nt)))...)
    execute([a.UPDATE table a.SET vals a.WHERE key == pk])
end

# Repo.delete!
function delete!(M, nt::NamedTuple) # throws Schema.PrimaryKeyError
    (key, pk) = _get_primary_key(M, nt)
    a = current_adapter()
    table = a.from(M)
    execute([a.DELETE a.FROM table a.WHERE key == pk])
end

end # module Octo.Repo
