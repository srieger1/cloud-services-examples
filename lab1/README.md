# Lab 1 - Containerization with Docker

See also, intro slides in moodle.

## Task 1
Take a look at Dockerfile and create an image named ubuntu-htop. Run it and experiment with the commands in the Dockerfile comments.

## Task 2
RECAP: Discuss in your group: What are the benefits and disadvantages of containers compared to VM or bare-metal?

## Task 3
Start nginx in a container showing a custom index.html that you mount (--mount or -v) in the container

## Task 4
Use `docker compose` to spin up and afterwards destroy multiple containers and its dependencies (network, storage). You can start with these examples:

* https://github.com/docker/awesome-compose/tree/master/react-express-mysql
* https://docs.docker.com/compose/gettingstarted