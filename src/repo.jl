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
function config(; adapter::Module, database::String)
    sym = nameof(adapter)
    DatabaseID = getfield(AdapterBase.Database, Symbol(sym, :Database))
    AdapterBase.current[:database] = DatabaseID()

    current[:adapter] = adapter
    loader = Backends.backend(adapter)
    current[:loader] = loader
    Base.invokelatest(loader.load, database)
end

# Repo.query
function query(stmt::Structured)
    a = current_adapter()
    sql = a.to_sql(stmt)
    loader = current_loader()
    loader.query(sql)
end

function query(stmt::Structured, vals::Tuple)
    a = current_adapter()
    sql = a.to_sql(stmt)
    loader = current_loader()
    loader.query(sql, collect(vals))
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

# Repo.insert!
function insert!(M, changes::NamedTuple)
    a = current_adapter()
    table = a.from(M)
    fieldnames = a.Enclosed(keys(changes))
    paramholders = a.Enclosed(fill(a.QuestionMark, length(changes)))
    query([a.INSERT a.INTO table fieldnames a.VALUES paramholders], values(changes))
end

# Repo.update!
function update!(M, changes::NamedTuple) # throws Schema.PrimaryKeyError
    (key, pk) = _get_primary_key(M, changes)
    a = current_adapter()
    table = a.from(M)
    query([a.UPDATE table a.SET changes a.WHERE key == pk])
end

# Repo.delete!
function delete!(M, changes::NamedTuple) # throws Schema.PrimaryKeyError
    (key, pk) = _get_primary_key(M, changes)
    a = current_adapter()
    table = a.from(M)
    query([a.DELETE a.FROM table a.WHERE key == pk])
end

end # module Octo.Repo
