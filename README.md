# Emercoin Docker Build
Docker image project
Build for amd64:
```
docker buildx build -t wg00/emercoin:amd64-0.7.12 .
```

Build for arm64:
```
sudo docker build --build-arg ARG_ARCH=aarch64 -t wg00/emercoin:arm64v8-0.7.12 .
```
