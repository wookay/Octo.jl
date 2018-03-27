using Documenter
using Octo
import Octo: Repo, Schema

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
        "keywords and aggregate functions" => "keywords_and_aggregates.md",
        "SQL elements" => "elements.md",
        "Adapters" => [
            "adapters/SQL.md",
            "adapters/PostgreSQL.md",
            "adapters/MySQL.md",
            "adapters/SQLite.md",
        ],
    ],
    html_prettyurls = !("local" in ARGS),
)
