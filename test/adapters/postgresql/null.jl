module adapters_postgresql_null_test

using Test
using Octo.Adapters.PostgreSQL

Repo.debug_sql()

Repo.connect(
    adapter = Octo.Adapters.PostgreSQL,
    dbname = "postgresqltest",
    user = "postgres",
)

struct Book
end
Schema.model(Book, table_name="book")

Repo.execute([DROP TABLE IF EXISTS Book])
Repo.execute(Raw("""
    CREATE TABLE book (
      id SERIAL PRIMARY KEY,
      title VARCHAR(255),
      publisher_description VARCHAR(255) NULL
    );
    """))

# https://discourse.julialang.org/t/how-to-pass-a-null-value-to-a-prepared-statement-with-libpq-jl/25068/2

Repo.insert!(Book, (title="Julia",))
Repo.insert!(Book, (title="O'Neil and the Martians", publisher_description=missing))

df = Repo.query(Book)
@test ismissing(df[1].publisher_description)
@test ismissing(df[2].publisher_description)

Repo.disconnect()

end # module adapters_postgresql_null_test
