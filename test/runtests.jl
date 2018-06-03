using Test

ignores = [joinpath("adapters", "jdbc"),
           joinpath("adapters", "odbc"),
           joinpath("adapters", "sqlite"), # temporal
    ]
if Sys.iswindows()
    push!(ignores, joinpath("adapters", "mysql"))
    # push!(ignores, joinpath("adapters", "sqlite"))
end

all_tests = []
for (root, dirs, files) in walkdir(".")
    for filename in files
        !endswith(filename, ".jl") && continue
        "runtests.jl" == filename && continue
        filepath = joinpath(root, filename)[3:end]
        !isempty(ARGS) && !any(x->startswith(filepath, x), ARGS) && continue
        isempty(ARGS) && any(path->occursin(path, filepath), ignores) && continue
        push!(all_tests, filepath)
    end
end

for (idx, filepath) in enumerate(all_tests)
    numbering = string(idx, /, length(all_tests))
    ts = @testset "$numbering $filepath" begin
        include(filepath)
    end
end
