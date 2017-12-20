function SELECT()
end

function DISTINCT()
end

function FROM()
end

function AS(sym::Symbol)
end


function WHERE()
end

function LIMIT()
end

function OFFSET()
end


function INNER()
end

function OUTER()
end

function LEFT()
end

function JOIN()
end

function ON()
end


function ORDER()
end

function BY()
end

function ASC()
end

function DESC()
end


function GROUP()
end

function HAVING()
end


function AND()
end

function OR()
end

function NOT()
end


# sqlfuncs
COUNT(v) = SqlFunc(COUNT, (v,))
AVG(v) = SqlFunc(AVG, (v,))
SUM(v) = SqlFunc(SUM, (v,))
