module adapters_odbc_dataframes_test

using Test # @test
using Octo.Adapters.ODBC # Repo Schema

Repo.debug_sql()

Repo.connect(
    adapter  = Octo.Adapters.ODBC,
    database = Octo.DBMS.SQL,
    dsn      = "PgSQL-test",
    username = "postgres",
    password = "",
)

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
@test size(df) == (3,)
@test df == [(id=1, col1=1, col2=4.0, col3="hey"),
             (id=2, col1=2, col2=5.0, col3="there"),
             (id=3, col1=3, col2=6.0, col3="sailor")]

Repo.disconnect()

end # module adapters_odbc_dataframes_test
