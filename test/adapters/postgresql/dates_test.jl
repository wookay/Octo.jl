module adapters_postgresql_dates_test

using Test # @test
using Octo.Adapters.PostgreSQL # SELECT FROM WHERE NOW()

import Dates: Day
@test to_sql([SELECT * FROM :users WHERE :created_at <= NOW() - Day(30)]) ==
             "SELECT * FROM users WHERE created_at <= NOW() - INTERVAL '30 days'"
@test to_sql([SELECT * FROM :users WHERE :created_at <= NOW() + Day(30)]) ==
             "SELECT * FROM users WHERE created_at <= NOW() + INTERVAL '30 days'"

end # module adapters_postgresql_dates_test
