# see also: https://docs.docker.com/get-started/docker-concepts/building-images/writing-a-dockerfile/
# see also, example: https://github.com/docker/getting-started-todo-app
 
# each line (excluding comments) is a layer
 
# docker build . -t ubuntu-htop
# docker tag
 
# docker image ls
# docker image rm
 
# docker system prune
# docker system prune -a
 
# docker run -it ubuntu-htop
# docker run -it ubuntu-htop bash
# docker run -dit --name htop ubuntu-htop
# docker run -d -b .. -p .. --name nginx nginx
 
# docker ps
# docker ps -a
# docker kill
# docker rm
 
# docker restart
# docker pause
 
# docker login
# docker commit / docker push
# docker pull 
# docker export
# docker import
 
# docker exec
# docker logs
# docker attach
# docker cp
 
# docker volume
# docker network
 
# docker info
# docker inspect
# docker top
 
# docker init
# docker compose
 
FROM ubuntu:latest
 
RUN apt update
RUN apt install -y htop
 
#COPY hallo.txt 
#EXPOSE 80
#ENV a b
 
#USER nobody
#WORKDIR /home/nobody
 
CMD	[ "htop" ]
 
#FROM
