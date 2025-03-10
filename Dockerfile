FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git ca-certificates make bash gcc musl-dev libc-dev linux-headers

WORKDIR /build

# 先复制依赖文件
COPY go.mod go.sum ./

# 预先下载依赖
RUN go env -w GO111MODULE=on && \
    go env -w GOPROXY=https://goproxy.cn,direct && \
    go mod download

# 复制源代码
COPY . .

# 编译两个二进制文件
RUN CGO_ENABLED=1 go build -o goscheduler ./cmd/goscheduler && \
    CGO_ENABLED=1 go build -o goscheduler-node ./cmd/node

FROM alpine:3.7

RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S app \
    && adduser -S -g app app

RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

WORKDIR /app

# 复制两个二进制文件
COPY --from=builder /build/goscheduler .
COPY --from=builder /build/goscheduler-node .

# 使用脚本来根据参数选择运行哪个程序
COPY --from=builder /build/docker-entrypoint.sh .
RUN chmod 755 /app/docker-entrypoint.sh && \
    chown -R app:app ./

EXPOSE 5920 5921

USER app

ENTRYPOINT ["/app/docker-entrypoint.sh"]
