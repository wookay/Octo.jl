module adapters_mysql_execute_result_test

using Test # @test
using Octo.Adapters.MySQL # Repo Schema Raw USE INSERT

Repo.debug_sql()

include("options.jl")

Repo.connect(;
    adapter = Octo.Adapters.MySQL,
    Options.for_mysql...
)

struct Employee
end
Schema.model(Employee, table_name="Employee", primary_key="ID")

result = Repo.execute([DROP TABLE IF EXISTS Employee])
@test result === nothing

result = Repo.execute(Raw("""CREATE TABLE IF NOT EXISTS Employee
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
@test result === nothing

result = Repo.execute(Raw("""INSERT INTO Employee (Name, Salary, JoinDate, LastLogin, LunchTime, OfficeNo, JobType, Senior, empno)
                 VALUES
                 ('John', 10000.50, '2015-8-3', '2015-9-5 12:31:30', '12:00:00', 1, 'HR', b'1', 1301),
                 ('Tom', 20000.25, '2015-8-4', '2015-10-12 13:12:14', '13:00:00', 12, 'HR', b'1', 1422),
                 ('Jim', 30000.00, '2015-6-2', '2015-9-5 10:05:10', '12:30:00', 45, 'Management', b'0', 1567);
              """))
@test result.num_affected_rows == 3
inserted = Repo.execute_result(INSERT)
@test inserted.id == 1

changes = (Name="Tim", Salary=15000.50, JoinDate="2015-7-25", LastLogin="2015-10-10 12:12:25", LunchTime="12:30:00", OfficeNo=56, JobType="Accounts", empno=3200)
inserted = Repo.insert!(Employee, changes)
@test inserted.id == 4
@test inserted.num_affected_rows == 1

result = Repo.delete!(Employee, 1:5)
@test result.num_affected_rows == 4

result = Repo.execute("update Employee set Name = 'New Name' where ID > 100")
@test result.num_affected_rows == 0

result = Repo.execute("delete from Employee")
@test result.num_affected_rows == 0

Repo.disconnect()

end # module adapters_mysql_execute_result_test
