##### CHEAT SHEET FOR LAB 1 #####
# see also: https://docs.docker.com/get-started/docker-concepts/building-images/writing-a-dockerfile/
# see also, example: https://github.com/docker/getting-started-todo-app

### Building images ###
# docker build . -t ubuntu-htop
# docker tag

# .dockerignore file in the directory can be used to control files that are included in the build context (and will therefore not be included in the image)

### Listing and managing images ###
# docker image ls
# docker image rm

### Creating and running the image in a container ###
# docker run -it ubuntu-htop
# docker run -it ubuntu-htop bash
# docker run -dit --name htop ubuntu-htop
# docker run -d --name nginx harbor.cs.hs-fulda.de/docker.io/nginx
# docker run -d -v index.html:/var/run/docker.sock -p 8080:80 -e VAR="value" --restart always --name nginx harbor.cs.hs-fulda.de/docker.io/nginx

# see packages in docker hub, e.g.: https://hub.docker.com/search?q=nginx
# see options for nginx: https://hub.docker.com/_/nginx

### Risky... why?
# docker run --cap-add
# docker run --privileged
# docker run -v /var/run/docker.sock:/var/run/docker.sock

### Listing and managing containers ###
# docker ps
# docker ps -a
# docker kill
# docker rm

# docker restart
# docker pause

### Pushing an image to a registry ###
# docker login
# docker commit / docker push
# docker pull
# docker export
# docker import

# see also: https://docs.docker.com/reference/cli/docker/image/push/
# see also, for our registry (harbor): https://goharbor.io/docs/1.10/working-with-projects/working-with-images/pulling-pushing-images/

### Running and accessing containers ###
# docker exec
# docker logs
# docker attach
# docker cp

### Create boilerplate image for app containers ###
# docker init

### Multi-stage and docker compose ###
# see: https://docs.docker.com/build/building/multi-stage/
# docker build -t hello Dockerfile-multi-stage

# see: https://docs.docker.com/compose/
# docker compose up -d

### Managing container networks and storage (volumes) ###
# docker volume
# docker network

### Show system stats and status
# docker info
# docker inspect
# docker top
 
### System cleanup ###
# docker system prune
# docker system prune -a

### Regular minimalistic Dockerfile, including htop in latest ubuntu
### Source/root image:
FROM ubuntu:latest
# FROM alpine:latest
 
### Running commands in the container, on top of the root image, creates new layer on top for each RUN
RUN apt update
RUN apt install -y htop

### Copy files from the build env to the image
# COPY hallo.txt
### Expose tcp port 80 of the container, similar to -p named above
# EXPOSE 80
### Set env vars in the container, also possible using -e param
# ENV a b

### User and working directory to create the container
# USER nobody
# WORKDIR /home/nobody

### Default command to run inside the container
CMD	[ "htop" ]

# multi-stage would mean that more FROM are following...
# FROM --from=0 /dir/file /dir/file
