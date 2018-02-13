module Repo

import ..Backends
import ..AdapterBase
import ..Queryable: Structured

const current = Dict{Symbol, Union{Nothing, Module}}(
    :loader => nothing,
    :adapter => nothing
)

current_loader() = current[:loader]
current_adapter() = current[:adapter]

function config(; adapter::Module, database::String)
    sym = nameof(adapter)
    DatabaseID = getfield(AdapterBase.Database, Symbol(sym, :Database))
    AdapterBase.current[:database] = DatabaseID()

    current[:adapter] = adapter
    loader = Backends.backend(adapter)
    current[:loader] = loader
    Base.invokelatest(loader.load, database)
end

function query(stmt::Structured)
    a = current_adapter()
    sql = a.to_sql(stmt)
    loader = current_loader()
    Base.invokelatest(loader.all, sql)
end

function all(T)
    a = current_adapter()
    table = a.from(T)
    query([a.SELECT * a.FROM table])
end

function insert!
end

function update!
end

function delete!
end

end # module Octo.Repo
