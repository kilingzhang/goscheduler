GO111MODULE=on

.PHONY: build
build: goscheduler node

.PHONY: build-race
build-race: enable-race build

.PHONY: run
run: build kill
	./bin/goscheduler web -e dev & 
	./bin/goscheduler-node -m 127.0.0.1:5920

.PHONY: run-race
run-race: enable-race run

.PHONY: kill
kill:
	-killall goscheduler-node

.PHONY: goscheduler
goscheduler:
	go build $(RACE) -o bin/goscheduler ./cmd/goscheduler

.PHONY: node
node:
	go build $(RACE) -o bin/goscheduler-node ./cmd/node

.PHONY: test
test:
	go test $(RACE) ./...

.PHONY: test-race
test-race: enable-race test

.PHONY: enable-race
enable-race:
	$(eval RACE = -race)

.PHONY: package
package: build-vue statik
	bash ./package.sh

.PHONY: package-all
package-all: build-vue statik
	bash ./package.sh -p 'linux darwin windows'

.PHONY: build-vue
build-vue:
	cd web/vue && yarn run build
	cp -r web/vue/dist/* web/public/

.PHONY: install-vue
install-vue:
	cd web/vue && yarn install

.PHONY: run-vue
run-vue:
	cd web/vue && yarn run dev

.PHONY: statik
statik:
	go install github.com/rakyll/statik
	go generate ./...

.PHONY: lint
	golangci-lint run

.PHONY: clean
clean:
	rm -rf bin/goscheduler
	rm -rf bin/goscheduler-node

.PHONY: docker-build
docker-build:
	docker build --platform linux/amd64 -t goscheduler:latest -f Dockerfile.release .

.PHONY: docker-push
docker-push:
	@read -p "Enter Docker registry URL (e.g., registry.example.com): " REGISTRY && \
	docker tag goscheduler:latest $${REGISTRY}/goscheduler:latest && \
	docker push $${REGISTRY}/goscheduler:latest
