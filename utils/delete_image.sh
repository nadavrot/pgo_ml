#!/bin/bash

echo "Available containers:"
docker ps -aq

echo "Stopping all containers:"
docker stop $(docker ps -aq)

echo "Remove all containers:"
docker rm $(docker ps -aq)

echo "Delete the image:"
docker image remove llvmdev

