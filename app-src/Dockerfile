FROM golang:1.7 AS compiler
RUN go build hello.go -o hello

FROM scratch
COPY --from=compiler hello /
ENTRYPOINT ["/hello"]
