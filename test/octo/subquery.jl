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

end # module test_octo_subquery
