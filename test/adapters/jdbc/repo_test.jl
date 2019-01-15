# julia --handle-signals=no repo_test.jl

module adapters_jdbc_repo_test

using Test # @test
using Octo.Adapters.JDBC # Repo Schema Raw
import JDBC # pathof(JDBC) JDBC.usedriver JDBC.init JDBC.destroy

Repo.debug_sql()

jdbc_test_dir = normpath(dirname(pathof(JDBC)), "..", "test")
derby_jar = normpath(jdbc_test_dir, "derby.jar")
toursdb_jar = normpath(jdbc_test_dir, "toursdb.jar") 

JDBC.usedriver(derby_jar)
JDBC.init()

Repo.connect(
    adapter    = Octo.Adapters.JDBC,
    database   = Octo.DBMS.SQL,
    connection = (url="jdbc:derby:jar:($toursdb_jar)toursdb",),
)

struct Airline
end
Schema.model(Airline, table_name="airlines")

df = Repo.query(Airline)
@test size(df) == (2,)
@test df[1].AIRLINE == "AA"

flights = Repo.query([SELECT * FROM :flights])
@test size(flights) == (542,)
@test flights[1].FLIGHT_ID == "AA1111"

Repo.disconnect()


if isdir("tmptest")
    rm("tmptest", recursive=true)
end
@assert !isdir("tmptest")

Repo.connect(
    adapter    = Octo.Adapters.JDBC,
    database   = Octo.DBMS.SQL,
    connection = (url="jdbc:derby:tmptest", create=true),
)

struct FirstTable
end
Schema.model(FirstTable, table_name="firsttable")

Repo.execute(Raw("CREATE TABLE FIRSTTABLE (ID INT PRIMARY KEY, NAME VARCHAR(12))"))
multiple_changes = [
    (ID=10, NAME="TEN"),
    (ID=20, NAME="TWENTY"),
]
Repo.insert!(FirstTable, multiple_changes)
df = Repo.query(FirstTable)
@test size(df) == (2,)

Repo.disconnect()
rm("tmptest", recursive=true)

JDBC.destroy()

end # module adapters_jdbc_repo_test
