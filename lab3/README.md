# Lab 3 - Scripting and IaC

Task 1: Revisit cloud-init bash scripting versus cloud-config
* https://cloudinit.readthedocs.io/en/latest/ (cloud-init as de facto standard for Ubuntu, RedHat and even Windows cloud images)
* bash scripting using bash history, /var/log/cloud-init.log and /var/log/cloud-init-output.log
* https://cloudinit.readthedocs.io/en/latest/reference/examples.html

Task 2: IaC with terraform, opentofu etc.
* install terraform, create remote state backend
* run terraform examples to automate all manual tasks from lab 2 and combine it with lab 1 to install docker and run container inside a cloud instance

Task 3: Alternatives, extensions, discussion
* take a look at ansible or saltstack and see how they can be combined with terraform
* Discuss the pros and cons of terraform in your group
