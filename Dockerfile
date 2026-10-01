FROM golang:alpine AS builder
WORKDIR /app
COPY go.mod ./
COPY *.go ./
RUN go test ./...
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]