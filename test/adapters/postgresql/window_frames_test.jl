module adapters_postgresql_window_frames_test

using Test # @test
using Octo.Adapters.PostgreSQL # to_sql window SELECT FROM RANK OVER PARTITION BY ORDER DESC

u = window([PARTITION BY :depname ORDER BY :salary DESC])
@test to_sql([SELECT (:depname, :empno, :salary, over(RANK(), u)) FROM :empsalary]) ==
             "SELECT depname, empno, salary, RANK() OVER (PARTITION BY depname ORDER BY salary DESC) FROM empsalary"
@test to_sql([WINDOW :w AS u]) == "WINDOW w AS (PARTITION BY depname ORDER BY salary DESC)"

w = window([PARTITION BY :depname ORDER BY :salary DESC], :w)
@test to_sql([SELECT (:depname, :empno, :salary, over(RANK(), w)) FROM :empsalary]) ==
             "SELECT depname, empno, salary, RANK() OVER (PARTITION BY depname ORDER BY salary DESC) AS w FROM empsalary"
@test to_sql([WINDOW :w AS w]) == "WINDOW w AS (PARTITION BY depname ORDER BY salary DESC)"
@test to_sql([w.salary]) == "w.salary"

Repo.debug_sql()

Repo.connect(
    adapter = Octo.Adapters.PostgreSQL,
    sink = Vector{<:NamedTuple}, # DataFrames.DataFrame
    user = "postgres",
)


# https://robots.thoughtbot.com/postgres-window-functions
struct Post
end
Schema.model(Post, table_name="posts")

struct Comment
end
Schema.model(Comment, table_name="comments")

Repo.execute([DROP TABLE IF EXISTS :posts])
Repo.execute([DROP TABLE IF EXISTS :comments])

Repo.execute(Raw("""
CREATE TABLE posts (
  id integer PRIMARY KEY,
  body varchar,
  created_at timestamp DEFAULT current_timestamp
);

CREATE TABLE comments (
 id INTEGER PRIMARY KEY,
 post_id integer NOT NULL,
 body varchar,
 created_at timestamp DEFAULT current_timestamp
);

/* make two posts */
INSERT INTO posts VALUES (1, 'foo');
INSERT INTO posts VALUES (2, 'bar');

/* make 4 comments for the first post */
INSERT INTO comments VALUES (1, 1, 'foo old');
INSERT INTO comments VALUES (2, 1, 'foo new');
INSERT INTO comments VALUES (3, 1, 'foo newer');
INSERT INTO comments VALUES (4, 1, 'foo newest');

/* make 4 comments for the second post */
INSERT INTO comments VALUES (5, 2, 'bar old');
INSERT INTO comments VALUES (6, 2, 'bar new');
INSERT INTO comments VALUES (7, 2, 'bar newer');
INSERT INTO comments VALUES (8, 2, 'bar newest');
"""))

posts = from(Post, :posts)
comments = from(Comment, :comments)

q = [SELECT (as(posts.id, :post_id), as(comments.id, :comment_ids), as(comments.body, :body)) FROM posts LEFT OUTER JOIN comments ON posts.id == comments.post_id]
@test to_sql(q) == "SELECT posts.id AS post_id, comments.id AS comment_ids, comments.body AS body FROM posts LEFT OUTER JOIN comments ON posts.id = comments.post_id"
df = Repo.query(q)
@test size(df) == (8,)

comment_rank = window([PARTITION BY :post_id ORDER BY comments.created_at DESC], :comment_rank)
@test to_sql([DENSE_RANK() OVER comment_rank]) == "DENSE_RANK() OVER (PARTITION BY post_id ORDER BY comments.created_at DESC) AS comment_rank"
q = [SELECT (as(posts.id, :post_id), as(comments.id, :comment_id), as(comments.body, :body), over(DENSE_RANK(), comment_rank)) FROM posts LEFT OUTER JOIN comments ON posts.id == comments.post_id]
@test to_sql(q) == "SELECT posts.id AS post_id, comments.id AS comment_id, comments.body AS body, DENSE_RANK() OVER (PARTITION BY post_id ORDER BY comments.created_at DESC) AS comment_rank FROM posts LEFT OUTER JOIN comments ON posts.id = comments.post_id"
df = Repo.query(q)
@test size(df) == (8,)

comment_id = as(comments.id, :comment_id)
post_id = as(posts.id, :post_id)
body = as(comments.body, :body)
ranked_comments = from([SELECT (post_id, comment_id, body, over(DENSE_RANK(), comment_rank)) FROM posts LEFT OUTER JOIN comments ON posts.id == comments.post_id], :ranked_comments)
@test to_sql(ranked_comments) == "(SELECT posts.id AS post_id, comments.id AS comment_id, comments.body AS body, DENSE_RANK() OVER (PARTITION BY post_id ORDER BY comments.created_at DESC) AS comment_rank FROM posts LEFT OUTER JOIN comments ON posts.id = comments.post_id) AS ranked_comments"
q = [SELECT (:comment_id, :post_id, :body) FROM ranked_comments WHERE comment_rank < 4]
@test to_sql(q) == "SELECT comment_id, post_id, body FROM (SELECT posts.id AS post_id, comments.id AS comment_id, comments.body AS body, DENSE_RANK() OVER (PARTITION BY post_id ORDER BY comments.created_at DESC) AS comment_rank FROM posts LEFT OUTER JOIN comments ON posts.id = comments.post_id) AS ranked_comments WHERE comment_rank < 4"
df = Repo.query(q)
@test size(df) == (8,)

ranked_comments = from([SELECT (post_id, comment_id, body, over(DENSE_RANK(), comment_rank)) FROM posts LEFT OUTER JOIN comments ON posts.id == comments.post_id])
with = [WITH :ranked_comments AS ranked_comments]
@test to_sql(with) == "WITH ranked_comments AS (SELECT posts.id AS post_id, comments.id AS comment_id, comments.body AS body, DENSE_RANK() OVER (PARTITION BY post_id ORDER BY comments.created_at DESC) AS comment_rank FROM posts LEFT OUTER JOIN comments ON posts.id = comments.post_id)"

q = [with... SELECT (:post_id, :comment_id, :body) FROM :ranked_comments WHERE comment_rank < 4]
@test to_sql(q) == string(to_sql(with), ' ', "SELECT post_id, comment_id, body FROM ranked_comments WHERE comment_rank < 4")
df = Repo.query(q)
@test size(df) == (8,)


# https://stackoverflow.com/questions/12410791/difficult-for-me-postgres-sql-query
struct C
end
Schema.model(C, table_name="c")

struct D
end
Schema.model(D, table_name="d")

Repo.execute([DROP TABLE IF EXISTS :c])
Repo.execute([DROP TABLE IF EXISTS :d])
Repo.execute(Raw("""
CREATE TABLE c
  (
    id int NOT NULL PRIMARY KEY,
    aid int NOT NULL,
    bid int NOT NULL,
    units int NOT NULL
  );
CREATE TABLE d
  (
    id int NOT NULL PRIMARY KEY,
    open boolean NOT NULL,
    cid int NOT NULL
  );
"""))
Repo.insert!(C, [(2,3,5,4),(3,3,5,6),(4,4,6,8),(5,4,6,10),(6,7,8,9)])
Repo.insert!(D, [(1,true,2),(2,true,3),(3,true,3),(4,true,4)])

c = from(C, :c)
d = from(D, :d)
n = from([SELECT (:aid, as(COUNT(*), :cnt)) FROM c JOIN d ON (d.cid == c.id) GROUP BY :aid], :n)
@test to_sql(n)              ==           "(SELECT aid, COUNT(*) AS cnt FROM c JOIN d ON d.cid = c.id GROUP BY aid) AS n"
@test to_sql([WITH :n AS n]) == "WITH n AS (SELECT aid, COUNT(*) AS cnt FROM c JOIN d ON d.cid = c.id GROUP BY aid)"
@test to_sql([JOIN n])       == "JOIN n"
q = [WITH :n AS n SELECT (:aid, as(SUM(c.units) - COALESCE(n.cnt, 0), :difference)) FROM c LEFT JOIN n USING (:aid,) GROUP BY (:aid, n.cnt) ORDER BY :aid]
@test to_sql(q)              == "WITH n AS (SELECT aid, COUNT(*) AS cnt FROM c JOIN d ON d.cid = c.id GROUP BY aid) SELECT aid, (SUM(c.units) - COALESCE(n.cnt, 0)) AS difference FROM c LEFT JOIN n USING (aid) GROUP BY aid, n.cnt ORDER BY aid"

df = Repo.query(q)
@test Pretty.table(df) == """
|   aid |   difference |
| ----- | ------------ |
|     3 |            7 |
|     4 |           17 |
|     7 |            9 |
3 rows."""

Repo.disconnect()

end # module adapters_postgresql_window_frames_test
