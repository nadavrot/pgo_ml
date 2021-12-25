#!/bin/bash

echo "Creating a docker image:"
docker build -t llvmdev -f Dockerfile.llvm .
