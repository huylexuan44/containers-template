# syntax=docker/dockerfile:1

# Cross-compile: build trên ARM native, binary target linux/amd64 (wrangler/CF yêu cầu)
FROM --platform=$BUILDPLATFORM golang:1.22-alpine AS build

ARG TARGETOS=linux
ARG TARGETARCH

WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY container_src/go.mod ./
RUN go mod download

COPY container_src/*.go ./

ENV CGO_ENABLED=0
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -trimpath -ldflags="-s -w" -o /server .

FROM scratch
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /server /server
EXPOSE 8080

CMD ["/server"]
