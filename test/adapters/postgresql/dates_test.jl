module adapters_postgresql_dates_test

using Test # @test
using Octo.Adapters.PostgreSQL # SELECT FROM WHERE NOW() CURRENT_DATE extract

using Dates: DateTime, Year, Month, Day

@test to_sql([SELECT * FROM :users WHERE :created_at <= NOW() - Day(30)]) ==
             "SELECT * FROM users WHERE created_at <= NOW() - INTERVAL '30 days'"
@test to_sql([SELECT * FROM :users WHERE :created_at <= NOW() + Day(30)]) ==
             "SELECT * FROM users WHERE created_at <= NOW() + INTERVAL '30 days'"

struct License
end
Schema.model(License, table_name="licenses")
l = from(License)
@test to_sql([SELECT (l.purchased + l.valid * Day(1)) FROM l]) ==
             "SELECT purchased + valid * INTERVAL '1 day' FROM licenses"

@test to_sql([SELECT CURRENT_DATE + Day(1)]) ==
             "SELECT CURRENT_DATE + INTERVAL '1 day'"

timestamp = DateTime(2001,02,16, 20,38,40)
@test to_sql([SELECT extract(Month, timestamp)]) ==
             "SELECT EXTRACT(MONTH FROM TIMESTAMP '2001-02-16 20:38:40')"

months = Year(2) + Month(3)
@test to_sql([SELECT extract(Month, months)]) ==
             "SELECT EXTRACT(MONTH FROM INTERVAL '2 years 3 months')"

end # module adapters_postgresql_dates_test
