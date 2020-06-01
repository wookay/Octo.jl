module adapters_odbc_mariadb_repo_test

using Test # @test
using Octo.Adapters.ODBC # Repo Schema
using MariaDB_Connector_C_jll

Repo.debug_sql()

PLUGIN_DIR = joinpath(MariaDB_Connector_C_jll.artifact_dir, "lib", "mariadb", "plugin")

Repo.connect(
    adapter  = Octo.Adapters.ODBC,
    dsn      = "Driver={ODBC_Test_MariaDB};SERVER=127.0.0.1;PLUGIN_DIR=$PLUGIN_DIR;Option=67108864;CHARSET=utf8mb4;USER=root;PWD="
)

# Repo.execute([DROP DATABASE IF EXISTS :mysqltest])
# Repo.execute([CREATE DATABASE :mysqltest])
Repo.execute([USE :mysqltest])

# https://discourse.julialang.org/t/odbc-example-for-prepared-statement-doesnt-work
struct CoolTable
end
Schema.model(CoolTable, table_name="cool_table", primary_key="ID")

Repo.execute([DROP TABLE IF EXISTS CoolTable])
Repo.execute(Raw("""
    CREATE TABLE cool_table (
        ID SERIAL,
        col1 INTEGER,
        col2 FLOAT(8),
        col3 VARCHAR(255),
        PRIMARY KEY (ID)
    )"""))

Repo.insert!(CoolTable, [(col1=1, col2=4.0, col3="hey"),
                         (col1=2, col2=5.0, col3="there"),
                         (col1=3, col2=6.0, col3="sailor")])

df = Repo.query(CoolTable)
@info :df df
@test size(df) == (3,)
@test df[1].col3 == "hey"


struct Employee
end
Schema.model(Employee, table_name="Employee", primary_key="ID")

Repo.execute([DROP TABLE IF EXISTS Employee])
Repo.execute(Raw("""
    CREATE TABLE Employee (
        ID SERIAL,
        Name VARCHAR(255),
        Salary FLOAT(8),
        PRIMARY KEY (ID)
    )"""))

changes = (Name="John", Salary=10000.50)
Repo.insert!(Employee, changes)
changes = (Name="Cloris", Salary=20000.50)
Repo.insert!(Employee, changes)
df = Repo.query(Employee)
@info :df df
@test size(df) == (2,)
@test df[1].Name == "John"

Repo.disconnect()

end # module adapters_odbc_mariadb_repo_test
