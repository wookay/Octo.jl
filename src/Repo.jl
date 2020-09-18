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

"""
    Connection
"""
struct Connection
    use_multiple_databases::Bool
    dbname::String
    loader::Module
    conn
end

const ExecuteResult = NamedTuple

@enum RepoLogLevel::Int32 begin
    LogLevelDebugSQL = -1
    LogLevelInfo = 0
end

const current = Dict{Symbol, Union{Nothing, Module, Connection, RepoLogLevel}}(
    :adapter => nothing,
    :connection => nothing,
    :log_level => LogLevelInfo,
)

const color_params = (; color=:yellow,)
const color_multiple_database = (; color=:blue, bold=true)

current_connection() = current[:connection]
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
    set_log_level(debug ? LogLevelDebugSQL : LogLevelInfo)
end

function print_debug_sql_params(io, params)
    print(io, repeat(' ', 4))
    for (idx, x) in enumerate(params)
        printstyled(io, repr(x); color_params...)
        length(params) != idx && printstyled(io, ", ")
    end
end

function print_debug_sql(db::Connection, stmt::Structured, params = nothing)
    if current[:log_level] <= LogLevelDebugSQL
        buf = IOBuffer()
        io = IOContext(buf, :color=>true)
        if db.use_multiple_databases
            printstyled(io, string('(', db.dbname, ')'); color_multiple_database...)
            print(io, ' ')
        end
        show(io, MIME"text/plain"(), stmt)
        !(params isa Nothing) && print_debug_sql_params(io, params)
        println(io)
        @info String(take!(buf))
    end
end


# Repo.connect
"""
    Repo.connect(; adapter::Module, database::Union{Nothing,Type{D} where {D <: DBMS.AbstractDatabase}}=nothing, use_multiple_databases::Bool=false, kwargs...)::Connection
"""
function connect(; adapter::Module, database::Union{Nothing,Type{D} where {D <: DBMS.AbstractDatabase}}=nothing, use_multiple_databases::Bool=false, kwargs...)::Connection
    if database !== nothing
        adapter.Database[:ID] = database
    end
    AdapterBase.current[:database] = adapter.DatabaseID()
    current[:adapter] = adapter
    loader = Backends.backend(adapter)
    conn = Base.invokelatest(loader.db_connect; kwargs...)
    dbname = Base.invokelatest(loader.db_dbname, (; kwargs...))
    connection = Connection(use_multiple_databases, dbname, loader, conn)
    if !use_multiple_databases
        current[:connection] = connection
    end
    connection
end

# Repo.disconnect
"""
    Repo.disconnect(; db::Union{Nothing, Connection}=nothing)
"""
function disconnect(; db::Union{Nothing, Connection}=nothing)
    if db === nothing
        connection = current_connection()
        disconnected = connection.loader.db_disconnect(connection.conn)
        current[:adapter] = nothing
        current[:connection] = nothing
        disconnected
    else
        db.loader.db_disconnect(db.conn)
    end
end

function get_primary_key(M)::Union{Nothing,Symbol,Vector{Symbol}}
    Tname = Base.typename(M)
    tbl = Schema.tables[Tname]
    Base.get(tbl, :primary_key, nothing)
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
    Repo.query(stmt::Structured; db::Connection=current_connection())
"""
function query(stmt::Structured; db::Connection=current_connection())
    a = current_adapter()
    sql = a.to_sql(stmt)
    print_debug_sql(db, stmt)
    db.loader.query(db.conn, sql)
end

"""
    Repo.query(M::Type; db::Connection=current_connection())
"""
function query(M::Type; db::Connection=current_connection())
    a = current_adapter()
    table = a.from(M)
    query([a.SELECT * a.FROM table]; db=db)
end

"""
    Repo.query(from::FromItem; db::Connection=current_connection())
"""
function query(from::FromItem; db::Connection=current_connection())
    query(from.__octo_model; db=db)
end

"""
    Repo.query(subquery::SubQuery; db::Connection=current_connection())
"""
function query(subquery::SubQuery; db::Connection=current_connection())
    query(subquery.__octo_query; db=db)
end

"""
    Repo.query(rawquery::Octo.Raw; db::Connection=current_connection())
"""
function query(rawquery::Raw; db::Connection=current_connection())
    query([rawquery]; db=db)
end

### Repo.query - vals::Vector
"""
    Repo.query(stmt::Structured, vals::Vector; db::Connection=current_connection())
"""
function query(stmt::Structured, vals::Vector; db::Connection=current_connection()) # throw Backends.UnsupportedError
    a = current_adapter()
    prepared = a.to_sql(stmt)
    print_debug_sql(db, stmt, vals)
    db.loader.query(db.conn, prepared, vals)
end

### Repo.query - pk
"""
    Repo.query(M::Type, pk::Union{Int, String}; db::Connection=current_connection())
"""
function query(M::Type, pk::Union{Int, String}; db::Connection=current_connection()) # throw Schema.PrimaryKeyError
    a = current_adapter()
    table = a.from(M)
    key = _field_for_primary_key(M)
    query([a.SELECT * a.FROM table a.WHERE key == pk]; db=db)
end

"""
    Repo.query(from::FromItem, pk::Union{Int, String}; db::Connection=current_connection())
"""
function query(from::FromItem, pk::Union{Int, String}; db::Connection=current_connection()) # throw Schema.PrimaryKeyError
    query(from.__octo_model, pk; db=db)
end

### Repo.query - pk_range
"""
    Repo.query(M::Type, pk_range::UnitRange{Int64}; db::Connection=current_connection())
"""
function query(M::Type, pk_range::UnitRange{Int64}; db::Connection=current_connection()) # throw Schema.PrimaryKeyError
    a = current_adapter()
    table = a.from(M)
    key = _field_for_primary_key(M)
    query([a.SELECT * a.FROM table a.WHERE key a.BETWEEN pk_range.start a.AND pk_range.stop]; db=db)
end

"""
    Repo.query(from::FromItem, pk_range::UnitRange{Int64}; db::Connection=current_connection())
"""
function query(from::FromItem, pk_range::UnitRange{Int64}; db::Connection=current_connection()) # throw Schema.PrimaryKeyError
    query(from.__octo_model, pk_range; db=db)
end

### Repo.query - nt::NamedTuple
"""
    Repo.query(stmt::Structured, nt::NamedTuple; db::Connection=current_connection())
"""
function query(stmt::Structured, nt::NamedTuple; db::Connection=current_connection())
    a = current_adapter()
    v = vec(stmt)
    for (idx, kv) in enumerate(pairs(nt))
        key = a.Field(nothing, kv.first)
        push!(v, key == kv.second)
        idx != length(nt) && push!(v, a.AND)
    end
    query(v; db=db)
end

"""
    Repo.query(M::Type, nt::NamedTuple; db::Connection=current_connection())
"""
function query(M::Type, nt::NamedTuple; db::Connection=current_connection())
    a = current_adapter()
    table = a.from(M)
    v = [a.SELECT, *, a.FROM, table, a.WHERE]
    for (idx, kv) in enumerate(pairs(nt))
        key = Base.getproperty(table, kv.first)
        push!(v, key == kv.second)
        idx != length(nt) && push!(v, a.AND)
    end
    query(v; db=db)
end

"""
    Repo.query(from::FromItem, nt::NamedTuple; db::Connection=current_connection())
"""
function query(from::FromItem, nt::NamedTuple; db::Connection=current_connection())
    query(from.__octo_model, nt; db=db)
end

"""
    Repo.query(subquery::SubQuery, nt::NamedTuple; db::Connection=current_connection())
"""
function query(subquery::SubQuery, nt::NamedTuple; db::Connection=current_connection())
    query(subquery.__octo_query, nt; db=db)
end

"""
    Repo.query(rawquery::Octo.Raw, nt::NamedTuple; db::Connection=current_connection())
"""
function query(rawquery::Raw, nt::NamedTuple; db::Connection=current_connection())
    query([rawquery], nt; db=db)
end


# Repo.get
"""
    Repo.get(M::Type, pk::Union{Int, String}; db::Connection=current_connection())
"""
function get(M::Type, pk::Union{Int, String}; db::Connection=current_connection()) # throw Schema.PrimaryKeyError
    query(M, pk; db=db)
end

"""
    Repo.get(M::Type, pk_range::UnitRange{Int64}; db::Connection=current_connection())
"""
function get(M::Type, pk_range::UnitRange{Int64}; db::Connection=current_connection()) # throw Schema.PrimaryKeyError
    query(M, pk_range; db=db)
end

"""
    Repo.get(M::Type, nt::NamedTuple; db::Connection=current_connection())
"""
function get(M::Type, nt::NamedTuple; db::Connection=current_connection())
    query(M, nt; db=db)
end


# Repo.execute
"""
    Repo.execute(stmt::Structured; db::Connection=current_connection())
"""
function execute(stmt::Structured; db::Connection=current_connection())
    a = current_adapter()
    sql = a.to_sql(stmt)
    print_debug_sql(db, stmt)
    db.loader.execute(db.conn, sql)
end

"""
    Repo.execute(stmt::Structured, vals::Vector; db::Connection=current_connection())
"""
function execute(stmt::Structured, vals::Vector; db::Connection=current_connection())
    a = current_adapter()
    prepared = a.to_sql(stmt)
    print_debug_sql(db, stmt, vals)
    db.loader.execute(db.conn, prepared, vals)
end

"""
    Repo.execute(stmt::Structured, nts::Vector{<:NamedTuple}; db::Connection=current_connection())
"""
function execute(stmt::Structured, nts::Vector{<:NamedTuple}; db::Connection=current_connection())
    a = current_adapter()
    prepared = a.to_sql(stmt)
    print_debug_sql(db, stmt, nts)
    db.loader.execute(db.conn, prepared, nts)
end

execute(raw::AdapterBase.Raw; db::Connection=current_connection())                            = execute([raw]; db=db)
execute(raw::AdapterBase.Raw, nt::NamedTuple; db::Connection=current_connection())            = execute([raw], [nt]; db=db)
execute(raw::AdapterBase.Raw, nts::Vector{<:NamedTuple}; db::Connection=current_connection()) = execute([raw], nts; db=db)
execute(raw::AdapterBase.Raw, vals::Vector; db::Connection=current_connection())              = execute([raw], vals; db=db)


# Repo.insert!

function do_insert(block, a, returning::Union{Nothing,Symbol,Vector}, db::Connection)
    extra = []
    if a.DatabaseID === DBMS.PostgreSQL && returning !== nothing
        extra = vcat(a.RETURNING, returning isa Symbol ? returning : tuple(Symbol.(returning)...))
    end
    result = block(extra)
    if a.DatabaseID === DBMS.PostgreSQL
        result
    else
        execute_result(a.INSERT; db=db)
    end
end

"""
    Repo.insert!(M::Type, nts::Vector{<:NamedTuple}; returning::Union{Nothing,Symbol,Vector}=[:id], db::Connection=current_connection())
"""
function insert!(M::Type, nts::Vector{<:NamedTuple}; returning::Union{Nothing,Symbol,Vector}=get_primary_key(M), db::Connection=current_connection())
    if !isempty(nts)
        Schema.validates.(M, nts) # throw InvalidChangesetError
        a = current_adapter()
        table = a.from(M)
        nt = first(nts)
        fieldnames = a.Enclosed(collect(keys(nt)))
        values = a.placeholders(length(nt))
        do_insert(a, returning, db) do extra
            execute([a.INSERT a.INTO table fieldnames a.VALUES values extra...], nts; db=db)
        end
    else
        nothing
    end
end

"""
    Repo.insert!(M::Type, vals::Vector{<:Tuple}; returning::Union{Nothing,Symbol,Vector}=[:id], db::Connection=current_connection())
"""
function insert!(M::Type, vals::Vector{<:Tuple}; returning::Union{Nothing,Symbol,Vector}=get_primary_key(M), db::Connection=current_connection())
    if !isempty(vals)
        a = current_adapter()
        table = a.from(M)
        do_insert(a, returning, db) do extra
            execute([a.INSERT a.INTO table a.VALUES a.VectorOfTuples(vals) extra...]; db=db)
        end
    else
        nothing
    end
end

"""
    Repo.insert!(M, nt::NamedTuple; returning::Union{Noting,Symbol,Vector}=[:id], db::Connection=current_connection())
"""
function insert!(M, nt::NamedTuple; kwargs...)
    insert!(M, [nt]; kwargs...)
end


# Repo.execute_result

function execute_result(command::SQLKeyword; db::Connection=current_connection())::ExecuteResult
    db.loader.execute_result(db.conn, command)
end


# Repo.update!
"""
    Repo.update!(M::Type, nt::NamedTuple; db::Connection=current_connection())
"""
function update!(M::Type, nt::NamedTuple; db::Connection=current_connection()) # throw Schema.PrimaryKeyError
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
    execute(v, collect(values(rest)); db=db)
end

function vecjoin(elements::Array{E, N}, delim::D)::Vector{Union{E, D}} where  {E, N, D}
    first = true
    result = Vector{Union{E, D}}()
    for el in elements
        if first
            first = false
        else
            push!(result, delim)
        end
        push!(result, el)
    end
    result
end

# Repo.delete!
"""
    Repo.delete!(M::Type, nt::NamedTuple; db::Connection=current_connection())
"""
function delete!(M::Type, nt::NamedTuple; db::Connection=current_connection())
    a = current_adapter()
    table = a.from(M)
    execute(hcat([a.DELETE a.FROM table a.WHERE], vecjoin([a.Field(table, k) == v for (k, v) in pairs(nt)], a.AND)...); db=db)
end

"""
    Repo.delete!(M::Type, pk_range::UnitRange{Int64}; db::Connection=current_connection())
"""
function delete!(M::Type, pk_range::UnitRange{Int64}; db::Connection=current_connection()) # throw Schema.PrimaryKeyError
    a = current_adapter()
    table = a.from(M)
    key = _field_for_primary_key(M)
    execute([a.DELETE a.FROM table a.WHERE key a.BETWEEN pk_range.start a.AND pk_range.stop]; db=db)
end

end # module Octo.Repo
