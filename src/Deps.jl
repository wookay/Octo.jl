module Deps # Octo


# ERROR: Module Dates not found in current path.
# import Dates
Main.eval(:(using Dates)) #
const Dates = getfield(Main, :Dates) #

const DateTime = Dates.DateTime
const Time = Dates.Time
const DatePeriod = Dates.DatePeriod
const TimePeriod = Dates.TimePeriod
const CompoundPeriod = Dates.CompoundPeriod
const TimeType = Dates.TimeType

# DatePeriod
const Year = Dates.Year
const Month = Dates.Month
const Day = Dates.Day

# TimePeriod
const Hour = Dates.Hour
const Minute = Dates.Minute
const Second = Dates.Second


end # module Octo.Deps
