# module adapters_mysql

module Options

for_mysql = (
    hostname = get(ENV, "MYSQL_HOST", "localhost"),
    username = "root",
    password = get(ENV, "MYSQL_ROOT_PASWORD", ""),
    port = 3306,
    db = "mysqltest",
)

for_postgresql = (
    host = "localhost",
    dbname = "postgresqltest",
    user = "postgres",
    password = get(ENV, "PGPASSWORD", ""),
)

end # module Options

# module adapters_mysql
