module test_dataframes_df

using Test
using DataFrames

# result = Repo.query([SELECT * FROM Temp])
result = [(id=1, title="Hello"),
          (id=2, title="World"),
         ]

df = DataFrame(result, copycols=false)
@test df.id == [1, 2]
@test df.title == ["Hello", "World"]
@test size(df) == (2, 2)
@test result == NamedTuple.(eachrow(df))

end # module test_dataframes_df


using Jive
@If VERSION >= v"1.7" module test_dataframes_df_destructing

using Test
using DataFrames

result = [(id=1, title="Hello"),
          (id=2, title="World"),
         ]

df = DataFrame(result, copycols=false)

row = eachrow(df)[1]
(; id, title) = row
@test id == 1
@test title == "Hello"

titles = []
for (; title) in eachrow(df)
    push!(titles, title)
end
@test titles == ["Hello", "World"]

end # @If VERSION >= v"1.7" module test_dataframes_df_destructing
