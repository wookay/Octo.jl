module adapters_duckdb_read_csv_test

using Test # @test
using Octo.Adapters.DuckDB # to_sql

@test to_sql([read_csv("faulty.csv")]) == """
read_csv('faulty.csv')"""

@test to_sql([
        read_csv("faulty.csv", columns = ("name" => "VARCHAR", "age" => "INTEGER"), store_rejects = true)
    ]) == """
read_csv('faulty.csv', columns = {'name': 'VARCHAR', 'age': 'INTEGER'}, store_rejects = true)"""

@test to_sql([
        read_csv("faulty.csv", header = true)
    ]) == """
read_csv('faulty.csv', header = true)"""

@test to_sql([
        read_csv("faulty.csv", auto_type_candidates = ["BIGINT", "DATE"])
    ]) == """
read_csv('faulty.csv', auto_type_candidates = ['BIGINT', 'DATE'])"""

@test to_sql([
        read_csv("faulty.csv", columns = ("name" => "VARCHAR", "age" => "INTEGER"), header = true, sample_size = 20_000)
    ]) == """
read_csv('faulty.csv', columns = {'name': 'VARCHAR', 'age': 'INTEGER'}, header = true, sample_size = 20000)"""

end # module adapters_duckdb_read_csv_test
