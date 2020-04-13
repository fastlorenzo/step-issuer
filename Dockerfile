# Build the manager binary
FROM golang:1.12.5 as builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN GOPROXY="https://goproxy.io" GOMAXPROCS=8 go mod download

# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY controllers/ controllers/
COPY provisioners/ provisioners/

# Build
RUN echo $TARGETPLATFORM | cut -d '/' -f 2 > /tmp/arch
RUN cat /tmp/arch
RUN CGO_ENABLED=0 GOOS=linux GOARCH=`cat /tmp/arch` GOARM=7 GO111MODULE=on go build -a -o manager main.go

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM gcr.io/distroless/static:latest
WORKDIR /
COPY --from=builder /workspace/manager .
ENTRYPOINT ["/manager"]
