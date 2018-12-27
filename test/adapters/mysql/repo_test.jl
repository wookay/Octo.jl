module adapters_mysql_repo_test

using Test # @test
using Octo.Adapters.MySQL # Repo Schema Raw USE

Repo.debug_sql()

include("options.jl")
Repo.connect(;
    adapter = Octo.Adapters.MySQL,
    sink = Vector{<:NamedTuple}, # DataFrames.DataFrame
    Options.arguments...
)

struct Employee
end
Schema.model(Employee, table_name="Employee", primary_key="ID")

Repo.execute([DROP TABLE IF EXISTS Employee])
Repo.execute(Raw("""CREATE TABLE IF NOT EXISTS Employee
                 (
                     ID INT NOT NULL AUTO_INCREMENT,
                     Name VARCHAR(255),
                     Salary FLOAT(7,2),
                     JoinDate DATE,
                     LastLogin DATETIME,
                     LunchTime TIME,
                     OfficeNo TINYINT,
                     JobType ENUM('HR', 'Management', 'Accounts'),
                     Senior BIT(1),
                     empno SMALLINT,
                     PRIMARY KEY (ID)
                 );"""))
Repo.execute(Raw("""INSERT INTO Employee (Name, Salary, JoinDate, LastLogin, LunchTime, OfficeNo, JobType, Senior, empno)
                 VALUES
                 ('John', 10000.50, '2015-8-3', '2015-9-5 12:31:30', '12:00:00', 1, 'HR', b'1', 1301),
                 ('Tom', 20000.25, '2015-8-4', '2015-10-12 13:12:14', '13:00:00', 12, 'HR', b'1', 1422),
                 ('Jim', 30000.00, '2015-6-2', '2015-9-5 10:05:10', '12:30:00', 45, 'Management', b'0', 1567);
              """))

df = Repo.query(Employee)
@test size(df) == (3,)

df = Repo.get(Employee, 2)
@test df[1].Name == "Tom"
@test size(df) == (1,)

changes = (Name="Tim", Salary=15000.50, JoinDate="2015-7-25", LastLogin="2015-10-10 12:12:25",
           LunchTime="12:30:00", OfficeNo=56, JobType="Accounts", empno=3200)
Repo.insert!(Employee, changes)

df = Repo.get(Employee, (Name="Tim",))
@test size(df) == (1,)
@test df[1].Salary == 15000.50

changes = (ID=2, Name="Chloe", OfficeNo=56)
Repo.update!(Employee, changes)
df = Repo.get(Employee, 2)
@test df[1].Name == "Chloe"

Repo.delete!(Employee, changes)
df = Repo.get(Employee, 2)
@test size(df) == (0,)

Repo.disconnect()

end # module adapters_mysql_repo_test
