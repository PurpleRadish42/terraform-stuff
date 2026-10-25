# terraform-state

Creates the S3 bucket (in LocalStack) that all other folders use for remote state.

## First-time setup (or after LocalStack loses its data)

`terraform init` fails with `S3 bucket "terraform-up-and-running-state" does not exist`
because this config uses the same bucket it creates. Bootstrap it like this:

1. Comment out the whole `terraform { backend "s3" { ... } }` block in `main.tf`.
2. Create the bucket using local state:
   ```sh
   terraform init
   terraform apply
   ```
3. Uncomment the `backend "s3"` block.
4. Move the local state into the bucket:
   ```sh
   terraform init -migrate-state
   ```
   Answer `yes` when asked to copy the state.
5. Delete the leftover local state files:
   ```sh
   rm -f terraform.tfstate terraform.tfstate.backup
   ```

Now `terraform init` works here and in the other folders.
