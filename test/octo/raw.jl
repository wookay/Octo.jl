module test_octo_raw

using Test
using Octo.Adapters.SQL # Raw to_sql

text = """
SELECT a
FROM   b
WHERE  c"""

@test to_sql([Raw(text)]) == text

end # module test_octo_raw
