# Service workflow templates

`build.yml` is copied to `.github/workflows/build.yml` in each deployable
service repository by the Terraform configuration in `global/github.tf`.

Every service repository must provide `.github/scripts/test.sh`. The build
workflow runs that script with `bash` after checking out the selected branch.
The script owns all service-specific test setup, including installing Python or
Node dependencies, starting databases, and running the appropriate test suite.
