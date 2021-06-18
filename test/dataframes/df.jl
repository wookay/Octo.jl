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

end # module test_dataframes_df
