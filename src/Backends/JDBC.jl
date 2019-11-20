module JDBCLoader

# https://github.com/JuliaDatabases/JDBC.jl
using JDBC # v0.5.0
using DataFrames: DataFrame
using Octo.Repo: SQLKeyword, ExecuteResult
using Octo.Backends: UnsupportedError

const current = Dict{Symbol, Any}(
    :conn => nothing,
)

current_conn() = current[:conn]

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
    current[:conn] = conn
end

# db_disconnect
function db_disconnect()
    conn = current_conn()
    JDBC.close(conn)
    current[:conn] = nothing
end

function Vector{<:NamedTuple}(df::DataFrame)
    map(eachrow(df)) do x
        NamedTuple{keys(x)}(values(x))
    end
end

# query
function query(sql::String)
    conn = current_conn()
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

function query(prepared::String, vals::Vector)
    conn = current_conn()
    rs = prepared_execute(conn, prepared, vals)
    df = JDBC.load(DataFrame, rs)
    JDBC.close(rs)
    Vector{<:NamedTuple}(df)
end

# execute
function execute(sql::String)::ExecuteResult
    conn = current_conn()
    stmt = JDBC.createStatement(conn)
    n = JDBC.executeUpdate(stmt, sql)
    JDBC.close(stmt)
    ExecuteResult()
end

function execute(prepared::String, vals::Vector)::ExecuteResult
    conn = current_conn()
    n = prepared_execute(conn, prepared, vals)
    ExecuteResult()
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    conn = current_conn()
    for tup in nts
        vals = collect(tup)
        n = prepared_execute(conn, prepared, vals)
    end
    ExecuteResult()
end

# execute_result
function execute_result(command::SQLKeyword)::ExecuteResult
    ExecuteResult()
end

end # module Octo.Backends.JDBCLoader
