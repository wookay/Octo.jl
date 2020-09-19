module adapters_mysql_multiple_databases_test

using Test
using Octo.Adapters.MySQL
using Octo.Adapters.PostgreSQL

Repo.debug_sql()

include("options.jl")

myc = Repo.connect(;
    adapter = Octo.Adapters.MySQL,
    multiple = true,
    Options.arguments...
)

pgc = Repo.connect(
    adapter = Octo.Adapters.PostgreSQL,
    dbname = "postgresqltest2",
    user = "postgres",
    multiple = true,
)

struct Price
end
Schema.model(Price, table_name="prices", primary_key="ID")

for c in (myc, pgc)
    Repo.execute([DROP TABLE IF EXISTS Price], db=c)
end
Repo.execute(Raw("""CREATE TABLE IF NOT EXISTS prices
                 (
                     ID INT NOT NULL AUTO_INCREMENT,
                     name VARCHAR(255),
                     price FLOAT(7,2),
                     PRIMARY KEY (ID)
                 );"""), db=myc)
Repo.execute(Raw("""
    CREATE TABLE prices (
        ID SERIAL,
        name VARCHAR(255),
        price FLOAT(8),
        PRIMARY KEY (ID)
    )"""), db=pgc)

result = Repo.insert!(Price, (name = "Jessica", price = 70000.50); db=myc)
@test keys(result) == (:id, :num_affected_rows)
@test result.num_affected_rows == 1
result = Repo.insert!(Price, (name = "Jessica", price = 70000.50); db=pgc)
@test keys(result) == (:id, :num_affected_rows)
@test result.num_affected_rows == 1

df = Repo.query(Price, db=myc)
@test size(df) == (1,)
df = Repo.query(Price, db=pgc)
@test size(df) == (1,)

Repo.disconnect(db=myc)
Repo.disconnect(db=pgc)

end # module adapters_mysql_multiple_databases_test
