using Octo
using .Octo: Repo, Schema
using Documenter

makedocs(
    build = joinpath(@__DIR__, "local" in ARGS ? "build_local" : "build"),
    modules = [Octo],
    clean = false,
    format = :html,
    sitename = "Octo.jl 🐙",
    authors = "WooKyoung Noh",
    pages = Any[
        "Home" => "index.md",
        "Repo" => "Repo.md",
        "Schema" => "Schema.md",
        "Queryable" => "Queryable.md",
        "SQL keywords & functions" => "keywords_and_functions.md",
        "SQL elements" => "elements.md",
        "Adapters" => [
            "Adapters/SQL.md",
            "Adapters/PostgreSQL.md",
            "Adapters/MySQL.md",
            "Adapters/SQLite.md",
        ],
        "Pretty" => "Pretty.md",
    ],
    html_prettyurls = !("local" in ARGS),
)
