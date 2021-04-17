module adapters_postgresql_public_use_cases

# example for https://discourse.julialang.org/t/generating-insert-into-sql-statement/59106

using Test
using Octo.Adapters.PostgreSQL

Repo.debug_sql()

include("options.jl")

Repo.connect(;
    adapter = Octo.Adapters.PostgreSQL,
    Options.for_postgresql...
)

Repo.execute(Raw("""
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public.use_cases
(
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    name character varying(150) COLLATE pg_catalog."default" NOT NULL,
    description text COLLATE pg_catalog."default",
    input text COLLATE pg_catalog."default",
    output text COLLATE pg_catalog."default",
    business_value text COLLATE pg_catalog."default",
    business_kpi text COLLATE pg_catalog."default",
    accuracy_impact integer,
    workspace_id uuid NOT NULL,
    dataset_id uuid,
    is_favorite boolean NOT NULL DEFAULT false,
    default_f_experiment uuid,
    default_ad_experiment uuid,
    created_at timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    created_by uuid NOT NULL,
    updated_at timestamp without time zone,
    updated_by uuid,
    business_objective text COLLATE pg_catalog."default",
    CONSTRAINT use_cases_pkey PRIMARY KEY (id)
)
"""))

struct PublicUseCases
end
Schema.model(PublicUseCases, table_name="public.use_cases")

Repo.insert!(PublicUseCases, [
("ac7e086a-a7d5-4474-8ab4-e6b8c94994c7", "Edited name", "Edited description", "Edited input", "Edited output", "test", "test", 6, "3541ee59-d48e-4aaa-8f38-79554136462d", NULL, true, NULL, NULL, "2021-04-08 13:46:11.549539", "b306ec38-ee19-4af5-9e3a-a36d2c22fe85", "2021-04-08 13:46:11.954205", "b306ec38-ee19-4af5-9e3a-a36d2c22fe85", "test"),
("d1197838-17c7-43c9-80f3-91d745ac32a8", "xyz", NULL, NULL, NULL, NULL, NULL, NULL, "71ecb06c-2555-4f2b-9b99-d1dc9c0876ca", "07b18f7a-35b6-423d-b252-daf26d6e2e1c", false, NULL, NULL, "2021-03-17 13:17:18.743356", "f31e650c-23b7-4886-a0a1-894c5eee9443", NULL, NULL, NULL),
("d726f6de-bd40-4c96-95c9-7bc080dab46d", "2 - with default exps", "something else again", "much data", "", "", "", NULL, "4e8fcfb2-4518-4445-afed-180941a0fd68", NULL, false, NULL, NULL, "2021-03-31 12:24:04.757653", "182b080b-8e42-4b85-82f5-e7e87bf8df0f", "2021-04-01 13:19:31.307656", "182b080b-8e42-4b85-82f5-e7e87bf8df0f", ""),
])

result = Repo.query([SELECT * FROM PublicUseCases])
@test length(result) == 3

Repo.delete!(PublicUseCases, (id="ac7e086a-a7d5-4474-8ab4-e6b8c94994c7",))
Repo.delete!(PublicUseCases, (id="d1197838-17c7-43c9-80f3-91d745ac32a8",))
Repo.delete!(PublicUseCases, (id="d726f6de-bd40-4c96-95c9-7bc080dab46d",))

result = Repo.query([SELECT * FROM PublicUseCases])
@test length(result) == 0

end # module adapters_postgresql_public_use_cases
