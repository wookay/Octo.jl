# module Octo

"""
    @sql_keywords(args...)
"""
macro sql_keywords(args...)
    esc(sql_keywords(args))
end
sql_keywords(s) = :(($(s...),) = $(map(Keyword, s)))

"""
    @sql_functions(args...)
"""
macro sql_functions(args...)
    esc(sql_functions(args))
end
sql_functions(s) = :(($(s...),) = $(map(x->SQLFunctionName(x), s)))

# module Octo
