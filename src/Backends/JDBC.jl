module JDBCLoader

# https://github.com/JuliaDatabases/JDBC.jl
using JDBC # v0.5.0
using DataFrames: DataFrame
using Octo.Repo: SQLKeyword, ExecuteResult
using Octo.Backends: UnsupportedError

# db_dbname
function db_dbname(nt::NamedTuple)::String
    nt.connection.url
end

# db_connect
function db_connect(; kwargs...)
    connection = getindex(kwargs, :connection)
    url = connection.url
    opts = collect(pairs(connection))[2:end]
    if isempty(opts)
        conn = JDBC.DriverManager.getConnection(url)
    else
        props = Dict([string.(kv) for kv in opts])
        conn = JDBC.DriverManager.getConnection(url, props)
    end
    conn
end

# db_disconnect
function db_disconnect(conn)
    JDBC.close(conn)
end

function Vector{<:NamedTuple}(df::DataFrame)
    map(eachrow(df)) do x
        NamedTuple{keys(x)}(values(x))
    end
end

# query
function query(conn, sql::String)
    stmt = JDBC.createStatement(conn)
    rs = JDBC.executeQuery(stmt, sql)
    df = JDBC.load(DataFrame, rs)
    JDBC.close(rs)
    JDBC.close(stmt)
    Vector{<:NamedTuple}(df)
end

function prepared_execute(conn, prepared::String, vals::Vector)
    ppstmt = JDBC.prepareStatement(conn, prepared)
    for (idx, val) in enumerate(vals)
        if val isa Int
            typ = :Int
        elseif val isa Float32
            typ = :Float
        elseif val isa Float64
            typ = :Double
        else
            typ = Symbol(typeof(val))
        end
        name = Symbol(:set, typ)
        if isdefined(JDBC, name)
            setter = getfield(JDBC, name)
            setter(ppstmt, idx, val)
        else
            throw(UnsupportedError(string(name, " is not defined in JDBC")))
        end
    end
    n = JDBC.executeUpdate(ppstmt)
    JDBC.close(ppstmt)
    n
end

function query(conn, prepared::String, vals::Vector)
    rs = prepared_execute(conn, prepared, vals)
    df = JDBC.load(DataFrame, rs)
    JDBC.close(rs)
    Vector{<:NamedTuple}(df)
end

# execute
function execute(conn, sql::String)::ExecuteResult
    stmt = JDBC.createStatement(conn)
    n = JDBC.executeUpdate(stmt, sql)
    JDBC.close(stmt)
    nothing
end

function execute(conn, prepared::String, vals::Vector)::ExecuteResult
    n = prepared_execute(conn, prepared, vals)
    nothing
end

function execute(conn, prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    for tup in nts
        vals = collect(tup)
        n = prepared_execute(conn, prepared, vals)
    end
    nothing
end

# execute_result
function execute_result(conn, command::SQLKeyword)::NamedTuple
    NamedTuple()
end

end # module Octo.Backends.JDBCLoader
