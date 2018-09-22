module test_octo_backends

using Test # @test_throws
using Octo: Backends

module UnsupportedAdapter
end

@test_throws Backends.UnsupportedError Backends.backend(UnsupportedAdapter)

end # module test_octo_backends
