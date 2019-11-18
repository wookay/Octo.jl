module adapters_postgresql_bigserial_pk_test

using Test # @test
using Octo.Adapters.PostgreSQL # Repo Raw Schema.model DROP TABLE IF EXISTS

Repo.debug_sql()

Repo.connect(
    adapter = Octo.Adapters.PostgreSQL,
    dbname = "postgresqltest",
    user = "postgres",
)

struct Post
end
Schema.model(Post, table_name="posts")

Repo.execute([DROP TABLE IF EXISTS Post])

Repo.execute(Raw("""
CREATE TABLE posts (
  id BIGSERIAL PRIMARY KEY,
  body varchar,
  created_at timestamp DEFAULT current_timestamp
);
"""))

posts = from(Post, :posts)

Repo.insert!(Post, (body="hello",))

df = Repo.query(Post)
@test df[1].body == "hello"
@test typeof(df[1].id) === Int64 # 8 bytes large autoincrementing integer

end # module adapters_postgresql_bigserial_pk_test
