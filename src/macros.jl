# module Octo

db_keywords      = String[]
db_functionnames = String[]

"""
    @sql_keywords(args...)
"""
macro sql_keywords(args...)
    esc(sql_keywords(args))
end
function sql_keywords(s)
    for keyword in s
        push!(db_keywords, String(keyword))
    end
    :(($(s...),) = $(map(SQLKeyword, s)))
end

"""
    @sql_functions(args...)
"""
macro sql_functions(args...)
    esc(sql_functions(args))
end
function sql_functions(s)
    for funcname in s
        push!(db_functionnames, String(funcname))
    end
    :(($(s...),) = $(map(x->SQLFunctionName(x), s)))
end

# module Octo
