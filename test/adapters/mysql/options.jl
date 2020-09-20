# module adapters_mysql

module Options

arguments = (
    username = "root",
    password = get(ENV, "MYSQL_ROOT_PASWORD", ""),
    hostname = "localhost",
    port = 3306,
    db = "mysqltest",
    unix_socket = Sys.islinux() ? "/var/run/mysqld/mysqld.sock" : "/tmp/mysql.sock",
)

end # module Options

# module adapters_mysql
