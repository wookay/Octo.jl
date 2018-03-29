# module adapters_mysql

module Options

arguments = (
    username = "root",
    password = "",
    hostname = "localhost",
    port = 3306,
    db = "mysqltest",
    unix_socket = haskey(ENV, "TRAVIS") ?  "/var/run/mysqld/mysqld.sock" :
                                           "/tmp/mysql.sock",
)

# TRAVIS
# TRAVIS_OS_NAME

end # module Options

# module adapters_mysql
