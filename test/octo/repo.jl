module test_octo_repo

using Test
using Octo.Adapters.SQL

Repo.connect(adapter=SQL)

Repo.query("select * from albums")
Repo.query(SubString("select * from albums"))
Repo.execute("select * from albums")
Repo.execute(SubString("select * from albums"))

end # module test_octo_repo
