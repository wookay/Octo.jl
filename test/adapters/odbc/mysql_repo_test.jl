module adapters_odbc_mysql_repo_test

using Test
using Octo.Adapters.ODBC

Repo.debug_sql()

#=
Repo.connect(
    adapter  = Octo.Adapters.ODBC,
    database = Octo.DBMS.MySQL,
    dsn      = "MySQL-test",
    username = "root",
    password = "",
)

Repo.disconnect()
=#

end # module adapters_odbc_mysql_repo_test
