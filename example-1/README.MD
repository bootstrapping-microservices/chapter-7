# Example-1

This example uses Terraform to create a Kubernetes cluster and deploys a **MongoDB database** to it.

Run this example using:

```bash
cd example-1/scripts
terraform apply
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name) --profile microservices
```

Note this assumes you've configured credentials for the profile **microservices** in your AWS credentials file, which for OSX and linux is in

```bash
~/.aws/credentials
```
