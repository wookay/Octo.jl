module test_octo_over

using Test
using Octo.Adapters.SQL # from to_sql

@test to_sql([over(DENSE_RANK(), [])]) == "DENSE_RANK() OVER ()"
@test to_sql([over(DENSE_RANK(), [ORDER BY :salary DESC])]) == "DENSE_RANK() OVER (ORDER BY salary DESC)"

w = window([ORDER BY :salary DESC])
@test to_sql([over(DENSE_RANK(), w)]) == "DENSE_RANK() OVER (ORDER BY salary DESC)"

w = window([ORDER BY :salary DESC], :w)
@test to_sql([over(DENSE_RANK(), w)]) == "DENSE_RANK() OVER (ORDER BY salary DESC) AS w"

end # module test_octo_over
