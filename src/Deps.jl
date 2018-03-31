# module Octo

module Deps
end # module Octo.Deps


# ERROR: Module Dates not found in current path.
# import Dates
Main.eval(:(using Dates)) #
const Dates = getfield(Main, :Dates) #
const Day = Dates.Day


# module Octo
