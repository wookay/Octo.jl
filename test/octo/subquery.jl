module test_octo_subquery

using Test # @test
using Octo.Adapters.SQL # Schema.model from to_sql SELECT SUM FROM WHERE ORDER BY

struct Album
end
Schema.model(Album, table_name="albums")

struct Track
end
Schema.model(Track, table_name="tracks")

albums = from(Album)
tracks = from(Track)

sub = from([SELECT SUM(:bytes) FROM tracks WHERE tracks.AlbumId == albums.AlbumId])
@test sub isa Octo.SubQuery
@test to_sql(sub) == "(SELECT SUM(bytes) FROM tracks WHERE AlbumId = AlbumId)"
q = [SELECT (:albumid, :title) FROM albums WHERE 10000000 > sub ORDER BY :title]
@test to_sql(q) == "SELECT albumid, title FROM albums WHERE 10000000 > (SELECT SUM(bytes) FROM tracks WHERE AlbumId = AlbumId) ORDER BY title"

sub = from([SELECT SUM(:bytes) FROM tracks WHERE tracks.AlbumId == albums.AlbumId], :sub)
@test to_sql(sub) == "(SELECT SUM(bytes) FROM tracks WHERE AlbumId = AlbumId) AS sub"
q = [SELECT (:albumid, :title) FROM albums WHERE 10000000 > sub ORDER BY :title]
@test to_sql(q) == "SELECT albumid, title FROM albums WHERE 10000000 > (SELECT SUM(bytes) FROM tracks WHERE AlbumId = AlbumId) AS sub ORDER BY title"

# https://youtu.be/baOAbOdcnxs?t=1948
struct SA
end
struct SB
end
struct SC
end
Schema.model(SA, table_name="A")
Schema.model(SB, table_name="B")
Schema.model(SC, table_name="C")
❔ = Octo.PlaceHolder
@test to_sql([1 + ❔]) == "1 + ?"
@test to_sql([❔ + 1]) == "? + 1"
A = from(SA, :A)
B = from(SB, :B)
C = from(SC, :C)
sub = from([SELECT (B.id, COUNT(*)) FROM B WHERE B.val == ❔ + 1 GROUP BY B.id], :B)
q = ([SELECT * FROM (A, C, sub) WHERE A.val == 123 AND A.id == C.a_id AND B.id == C.b_id])
@test to_sql(q) == "SELECT * FROM A, C, (SELECT B.id, COUNT(*) FROM B WHERE B.val = ? + 1 GROUP BY B.id) AS B WHERE A.val = 123 AND A.id = C.a_id AND B.id = C.b_id"

end # module test_octo_subquery
