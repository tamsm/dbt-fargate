### [dbt](https://docs.getdbt.com/) on aws fargate

This is an attempt to simply run dbt containerised
on aws fargate. The plan is to:
- contain all aws resource needed for ECS/ECR setup under `components/dbt/`
- contain sample dbt project files under `project/`
- use `instances/kozmischeheide/dev/` to initialize the resources and project on dev account 
