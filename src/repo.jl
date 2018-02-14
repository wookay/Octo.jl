module Repo

import ..Backends
import ..AdapterBase
import ..Queryable: Structured
import ..Schema

const current = Dict{Symbol, Union{Nothing, Module}}(
    :loader => nothing,
    :adapter => nothing
)

current_loader() = current[:loader]
current_adapter() = current[:adapter]

# Repo.config
function config(; adapter::Module, kwargs...)
    sym = nameof(adapter)
    DatabaseID = getfield(AdapterBase.Database, Symbol(sym, :Database))
    AdapterBase.current[:database] = DatabaseID()

    current[:adapter] = adapter
    loader = Backends.backend(adapter)
    current[:loader] = loader
    Base.invokelatest(loader.load; kwargs...)
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
    loader = current_loader()
    loader.execute(sql)
end

function execute(stmt::Structured, values::Tuple)
    a = current_adapter()
    sql = a.to_sql(stmt)
    loader = current_loader()
    loader.execute(sql, values)
end

function execute(raw::AdapterBase.Raw)
    execute([raw])
end

function execute(raw::AdapterBase.Raw, values::Tuple)
    execute([raw], values)
end

# Repo.query
function query(stmt::Structured)
    a = current_adapter()
    sql = a.to_sql(stmt)
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

function _get_primary_key(M, changes::NamedTuple) # throws Schema.PrimaryKeyError
    Tname = Base.typename(M)
    info = Schema.tables[Tname]
    if haskey(info, :primary_key)
        a = current_adapter()
        table = a.from(M)
        primary_key = Symbol(info[:primary_key])
        key = Base.getproperty(table, primary_key)
        pk = getfield(changes, primary_key)
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

function get(M, tup::NamedTuple)
    a = current_adapter()
    table = a.from(M)
    v = [a.SELECT, *, a.FROM, table, a.WHERE]
    for (idx, kv) in enumerate(pairs(tup))
        key = Base.getproperty(table, kv.first)
        push!(v, key == kv.second)
        idx != length(tup) && push!(v, a.AND)
    end
    query(v)
end

# Repo.insert!
function insert!(M, changes::NamedTuple)
    a = current_adapter()
    table = a.from(M)
    fieldnames = a.Enclosed(keys(changes))
    execute([a.INSERT a.INTO table fieldnames a.VALUES a.paramholders(changes)], values(changes))
end

# Repo.update!
function update!(M, changes::NamedTuple) # throws Schema.PrimaryKeyError
    (key, pk) = _get_primary_key(M, changes)
    a = current_adapter()
    table = a.from(M)
    vals = (; filter(kv -> kv.first != key, collect(pairs(changes)))...)
    execute([a.UPDATE table a.SET vals a.WHERE key == pk])
end

# Repo.delete!
function delete!(M, changes::NamedTuple) # throws Schema.PrimaryKeyError
    (key, pk) = _get_primary_key(M, changes)
    a = current_adapter()
    table = a.from(M)
    execute([a.DELETE a.FROM table a.WHERE key == pk])
end

end # module Octo.Repo
