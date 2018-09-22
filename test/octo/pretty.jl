module test_octo_pretty

using Test
using Octo: Pretty

nts = [(id=1,name="John"),(id=2,name="Tom")]
@test Pretty.table(nts) == """
|   id | name   |
| ---- | ------ |
|    1 | John   |
|    2 | Tom    |
2 rows."""

Pretty.set(colsize=30)
nts = [(id=1,case="글씨가 넘흐 길어서 짤릴 때"),
       (id=2,case="글씨에 점  하나가"),
       (id=3,case="안짤리는 넘")]
@test Pretty.table(nts) == """
|   id | case              |
| ---- | ----------------- |
|    1 | 글씨가 넘흐 길... |
|    2 | 글씨에 점  하나가 |
|    3 | 안짤리는 넘       |
3 rows."""

nts = Vector{NamedTuple{(:a,),Tuple{Int}}}()
@test Pretty.table(nts) == """
| a   |
| --- |

0 rows."""

Pretty.set(false)
buf = IOBuffer()
Base.show(buf, MIME"text/plain"(), nts)
@test String(take!(buf)) == """
NamedTuple{(:a,),Tuple{Int64}}[]"""
Pretty.set(true)

@test Pretty._regularize_text("가1", 1) == "가"

end # module test_octo_pretty
