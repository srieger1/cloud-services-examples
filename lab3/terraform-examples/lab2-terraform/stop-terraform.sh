#!/bin/bash

# let terraform remove the resources specified in .tf file in same directory
./terraform destroy

# you can also use "terraform destroy -auto-approve" to prevent terraform from asking back whether it should proceed
