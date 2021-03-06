# Inspired by https://container-solutions.com/faster-builds-in-docker-with-go-1-11/
# Base build image
FROM golang:1.11.2-alpine3.8 AS build_base
RUN apk add bash make git curl unzip rsync libc6-compat gcc musl-dev
WORKDIR /go/src/github.com/y0sher/oracle_server

# Force the go compiler to use modules
ENV GO111MODULE=on

# We want to populate the module cache based on the go.{mod,sum} files.
COPY go.mod .
COPY go.sum .

# Download dependencies
RUN go mod download

COPY setup_env.sh .
COPY scripts/* scripts/

RUN ./setup_env.sh

# This image builds the go-spacemesh server
FROM build_base AS server_builder
# Here we copy the rest of the source code
COPY . .

# And compile the project
RUN make build

#In this last stage, we start from a fresh Alpine image, to reduce the image size and not ship the Go compiler in our production artifacts.
FROM alpine AS oracle

# Finally we copy the statically compiled Go binary.
COPY --from=server_builder /go/src/github.com/y0sher/oracle_server/oracle_server /bin/oracle_server
ENTRYPOINT ["/bin/oracle_server"]
EXPOSE 3030
