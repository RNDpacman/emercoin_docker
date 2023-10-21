# Emercoin Docker Build
Docker image project
Build for amd64 (default version 0.8.3):
```
docker buildx build --build-arg -t emercoin-amd64:0.8.3 .
```

Build for arm64 (default x86_64):
```
sudo docker build --build-arg EMC_VER=v0.8.3emc ARCH=aarch64 -t emercoin-arm64:0.8.3 .
```
Build for other version (default 0.8.3):
```
docker buildx build --build-arg EMC_VER=v0.8.2emc -t emercoin-amd6:0.8.2 .
```
