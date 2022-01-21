module DuckDBLoader

# https://github.com/kimmolinna/DuckDB.jl
using DuckDB
using .DuckDB.DBInterface

using Octo: Repo, AdapterBase, DBMS, SQLElement, Structured
using .Repo: SQLKeyword, ExecuteResult

# db_dbname
function db_dbname(nt::NamedTuple)::String
    ""
end

# db_connect
function db_connect(; file::String=":memory:")
    DuckDB.DB(file)
end

# db_disconnect
function db_disconnect(db::DuckDB.DB)
    DBInterface.close!(db::DuckDB.DB)
end

# query
function query(db::DuckDB.DB, sql::String)
    res = DBInterface.execute(db, sql)
    DuckDB.toDataFrame(res)
end

# execute
function execute(db::DuckDB.DB, sql::String)::ExecuteResult
    result = DBInterface.execute(db, sql)
    nothing
end

function execute(db::DuckDB.DB, prepared::String, nts::Vector{<:NamedTuple})::ExecuteResult
    # stmt = DBInterface.prepare(db, prepared)
    # for tup in nts
    #     result = DBInterface.execute(stmt, collect(tup))
    # end
    nothing
end

function Base.show(io::IO, mime::MIME"text/plain", element::Union{E,Structured} where E<:SQLElement)
    dbms = DBMS.DuckDB()
    AdapterBase._show(io, mime, dbms, element)
end

end # module Octo.Backends.DuckDBLoader
