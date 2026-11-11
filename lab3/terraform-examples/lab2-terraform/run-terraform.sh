#!/bin/bash

# initialization of terraform state and download openstack plugin/dependencies
./terraform init

# show what will done
./terraform plan

# let terraform create the resources specified in .tf file in same directory
./terraform apply

# you can also use "terraform apply -auto-approve" to prevent terraform from asking back whether it should proceed

# among the benefits of terraform, is that is deploys the resources rather quick. It identifies dependencies and
# deploys independent resources in parallel.
# "terraform graph" creates a dependency graph of the resource specified in the .tf file
# another benefit of terraform is, that it does the heavy lifting to support the APIs of multiple cloud
# providers and supports way more features and cloud services than, e.g., libcloud, hence it's quite popular
#
# among the drawbacks however is, that it comes with its own definition language and does not offer the full
# flexibility of a programming language. In this regard, libcloud, boto3, openstack-sdk etc. are way more flexible
#
# we discuss different cloud service deployment solutions and their pros/cons in the course