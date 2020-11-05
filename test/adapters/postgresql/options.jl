# module adapters_postgresql

module Options

for_postgresql = (
    host = "localhost",
    dbname = "postgresqltest",
    user = "postgres",
    password = get(ENV, "PGPASSWORD", ""),
)

end # module Options

# module adapters_postgresql
