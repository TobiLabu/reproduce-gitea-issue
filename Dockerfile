FROM alpine:3.20

RUN apk add --no-cache tea netcat-openbsd git curl
VOLUME ["/git"]
# Just something to keep the container running for further use from the script
ENTRYPOINT ["nc", "-l", "1234"]
