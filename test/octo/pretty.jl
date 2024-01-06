module test_octo_pretty

using Test
using Octo.Pretty

nts = [(id=1, name="John"), (id=2, name="Tom")]
@test Pretty.table(nts) == """
|   id | name   |
| ---- | ------ |
|    1 | John   |
|    2 | Tom    |
2 rows."""

Pretty.set(colsize=30)
nts = [(id=1, case="글씨가 넘흐 길어서 짤릴 때"),
       (id=2, case="글씨에 점  하나가"),
       (id=3, case="글씨가 거의 비슷해"),
       (id=4, case="안짤리는 넘")]
@test Pretty.table(nts) == """
|   id | case              |
| ---- | ----------------- |
|    1 | 글씨가 넘흐 길... |
|    2 | 글씨에 점  하나가 |
|    3 | 글씨가 거의 비... |
|    4 | 안짤리는 넘       |
4 rows."""

nts = Vector{NamedTuple{(:a,),Tuple{Int}}}()
@test Pretty.table(nts) == """
| a   |
| --- |
empty row."""

Pretty.set(false)
@test contains(sprint(show, nts), "NamedTuple{")
Pretty.set(true)

@test Pretty._regularize_text("가1", 1) == "."
@test Pretty._regularize_text("가1", 2) == "가"
@test Pretty._regularize_text("가1", 3) == "가1"

nt = NamedTuple{(:id, :name, :salary),Tuple{Union{Missing, Int32},Union{Missing, String},Union{Missing, Float32}}}((1, "John", 10000.5f0))
@test Pretty.table(nt) == """
|   id | name   |    salary |
| ---- | ------ | --------- |
|    1 | John   |   10000.5 |"""

end # module test_octo_pretty
