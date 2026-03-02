FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
COPY *.go .
RUN go build -o registry .

FROM alpine:3.21
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /app/registry .
EXPOSE 8080
CMD ["./registry"]
