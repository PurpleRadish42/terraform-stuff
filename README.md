# terraform-stuff

<p align="center">
  <img src="assets/terminal.svg" width="840" alt="Animated terminal: terraform apply creates a load-balanced Auto Scaling group and prints the load balancer DNS name">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Terraform-1.16-7B42BC?logo=terraform&logoColor=white" alt="Terraform 1.16">
  <img src="https://img.shields.io/badge/AWS_provider-~%3E_6.0-FF9900" alt="AWS provider ~> 6.0">
  <img src="https://img.shields.io/badge/floci-2.1.0-2ea44f" alt="floci 2.1.0">
  <img src="https://img.shields.io/badge/AWS_bill-%240-brightgreen" alt="AWS bill: $0">
</p>

Terraform code for AWS, applied against [floci](https://floci.io), a local AWS emulator that runs in Docker, instead of a real account. Nothing here costs anything to create or destroy.

## How the load-balanced project fits together

<p align="center">
  <img src="assets/architecture.svg" width="840" alt="Architecture: Terraform calls the emulated AWS API, which creates a load balancer, target group, launch configuration and an Auto Scaling group of two EC2 web servers. Requests go from the browser through the load balancer and target group to the instances in turn.">
</p>

Terraform talks to floci's AWS API on `localhost:4566`. Floci starts each EC2 instance as a Docker container and runs a real listener for the load balancer, so a request to the load balancer's DNS name is forwarded to one of the instances.

## Run it

You need Docker, Terraform and `make`.

```sh
make aws                 # start floci: AWS API on :4566, web UI on :4500
cd ec2-launch-template
terraform init
terraform apply
```

On floci 2.1.0 the load balancer can't reach its instances until the emulator is attached to the Docker network it creates for the VPC ([floci issue #3846](https://github.com/floci-io/floci/issues/3846)). After `terraform apply`, run:

```sh
docker network connect floci-vpc-4566-ap-south-1-vpc-default-ap-south-1 floci-aws
```

Then open the `alb_dns_name` from the Terraform output. When you're done:

```sh
terraform destroy
make aws-down
```

Deploy one project at a time: they all share one emulated VPC, so resource names can clash.

Floci runs in persistent storage mode with its data in the `floci-data` Docker volume, so S3 buckets (including Terraform state) survive `make aws-down` and a reboot. To start from an empty emulator, run `docker volume rm floci-data` after `make aws-down`.

## License

[Apache License 2.0](LICENSE)
