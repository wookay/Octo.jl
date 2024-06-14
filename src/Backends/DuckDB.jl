module DuckDBLoader

# https://github.com/duckdb/duckdb/tree/master/tools/juliapkg
using DuckDB
using .DuckDB: DBInterface
using DataFrames: DataFrame

using Octo: Repo, AdapterBase, DBMS, SQLElement, Structured
using .Repo: SQLKeyword, ExecuteResult

# db_dbname
function db_dbname(nt::NamedTuple)::String
    "DuckDB"
end

# db_connect
function db_connect(; file::String=":memory:")
    DBInterface.connect(DuckDB.DB, file)
end

# db_disconnect
function db_disconnect(con::DuckDB.DB)
    DBInterface.close!(con)
end

# query
function query(con::DuckDB.DB, sql::String)
    result = DBInterface.execute(con, sql)
    DataFrame(result)
end

# execute
function execute(con::DuckDB.DB, sql::String)::ExecuteResult
    result = DBInterface.execute(con, sql)
    if isempty(result)
        nothing
    else
        df = DataFrame(result)
        n = only(df[!, :Count])
        (Count = n,)
    end
end

function execute(con::DuckDB.DB, prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    stmt = DBInterface.prepare(con, prepared)
    cnt = 0
    for tup in nts
        result = DBInterface.execute(stmt, collect(tup))
        if !isempty(result)
            df = DataFrame(result)
            n = only(df[!, :Count])
            cnt += n
        end
    end
    (Count = cnt,)
end

function Base.show(io::IO, mime::MIME"text/plain", element::Union{E,Structured} where E<:SQLElement)
    dbms = DBMS.DuckDB()
    AdapterBase._show(io, mime, dbms, element)
end

end # module Octo.Backends.DuckDBLoader
