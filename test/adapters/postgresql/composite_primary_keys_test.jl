module adapters_postgresql_composite_primary_keys_test

using Test
using Octo.Adapters.PostgreSQL

Repo.debug_sql()

include("options.jl")

Repo.connect(;
    adapter = Octo.Adapters.PostgreSQL,
    Options.for_postgresql...
)

struct CourseGrade
end
Schema.model(CourseGrade, table_name="course_grades", primary_key=(:quarter_id, :course_id, :student_id))
# Schema.model(CourseGrade, table_name="course_grades", primary_key=("quarter_id", "course_id", "student_id"))
# Schema.model(CourseGrade, table_name="course_grades", primary_key="(quarter_id, course_id, student_id)")

Repo.execute([DROP TABLE IF EXISTS CourseGrade])

Repo.execute(Raw("""
CREATE TABLE course_grades (
    quarter_id INTEGER,
    course_id TEXT,
    student_id INTEGER,
    grade INTEGER,
    PRIMARY KEY(quarter_id, course_id, student_id)
);
"""))

result = Repo.insert!(CourseGrade, (quarter_id=1, course_id="art", student_id=1, grade=5))
@test result.num_affected_rows == 1

result = Repo.insert!(CourseGrade, (quarter_id=1, course_id="music", student_id=1, grade=3))
@test result.num_affected_rows == 1

course_grades = Repo.get(CourseGrade, (quarter_id=1, student_id=1))
@test length(course_grades) == 2

result = Repo.delete!(CourseGrade, (course_id="art",))
@test result.num_affected_rows == 1

course_grades = Repo.query(CourseGrade)
@test length(course_grades) == 1

end # module adapters_postgresql_composite_primary_keys_test
