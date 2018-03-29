using Test
import Octo: Pretty

function read_stdout(f)
    oldout = stdout
    rdout, wrout = redirect_stdout()
    out = @async read(rdout, String)
    f()
    redirect_stdout(oldout)
    close(wrout)
    rstrip(fetch(out))
end

nts = [(id=1,name="John"),(id=2,name="Tom")]
s = read_stdout() do
    Pretty.show(stdout, MIME"text/plain"(), nts)
end
@test s == """
|   id | name   |
| ---- | ------ |
|    1 | John   |
|    2 | Tom    |
2 rows."""

nts = [(id=1,case="글씨가 넘흐 길어서 짤릴 때"),(id=2,case="안짤리는 넘")]
s = read_stdout() do
    Pretty.show(stdout, MIME"text/plain"(), nts)
end
@test s == """
|   id | case              |
| ---- | ----------------- |
|    1 | 글씨가 넘흐 길..  |
|    2 | 안짤리는 넘       |
2 rows."""
