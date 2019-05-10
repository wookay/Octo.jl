module HiveLoader

# https://github.com/JuliaDatabases/Hive.jl v0.3.0
using Hive # HiveSession HiveAuth
using Octo.Repo: ExecuteResult

const current = Dict{Symbol, Any}(
    :sess => nothing,
)

current_sess() = current[:sess]

# db_connect
function db_connect(; host::String="localhost", port::Integer=10000, auth::HiveAuth=HiveAuth(), tprotocol::Symbol=:binary)
    sess = HiveSession(host, port, auth; tprotocol=tprotocol)
    current[:sess] = sess
end

# db_disconnect
function db_disconnect()
    sess = current_sess()
    if sess isa HiveSession
        Hive.close(sess)
        current[:sess] = nothing
    end
end

# query
function query(sql::String)
    sess = current_sess()
    pending = Hive.execute(sess, sql)
    rs = Hive.result(pending)
    sch = Hive.schema(rs)
    column_names = tuple(Symbol.(getproperty.(sch.columns, :columnName))...)
    df = reduce(vcat, Hive.records(rs))
    nts = NamedTuple{column_names}.(df)
    Hive.close(rs)
    nts
end

function query(prepared::String, vals::Vector) # throw UnsupportedError
    throw(UnsupportedError("needs to be implemented"))
end

# execute
function execute(sql::String)::ExecuteResult
    sess = current_sess()
    result = Hive.execute(sess, sql)
    ExecuteResult()
end

function execute(prepared::String, vals::Vector)::ExecuteResult # throw UnsupportedError
    throw(UnsupportedError("needs to be implemented"))
end

function execute(prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult # throw UnsupportedError
    throw(UnsupportedError("needs to be implemented"))
end

end # module Octo.Backends.HiveLoader
