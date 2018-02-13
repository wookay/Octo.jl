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

function all(M)
    a = current_adapter()
    table = a.from(M)
    query([a.SELECT * a.FROM table])
end

function get(M, pk::Union{Int, String})
    Tname = Base.typename(M)
    info = Schema.tables[Tname]
    if haskey(info, :primary_key)
        a = current_adapter()
        table = a.from(M)
        primary_key = Base.getproperty(table, Symbol(info[:primary_key]))
        query([a.SELECT * a.FROM table a.WHERE primary_key == pk])
    else
        throws(Schema.PrimaryKeyError(""))
    end
end

function insert!
end

function update!
end

function delete!
end

end # module Octo.Repo
