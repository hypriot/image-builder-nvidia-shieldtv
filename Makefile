default: build

build:
	docker build -t image-builder-nvidia-shieldtv .

image: build
	docker run --rm -v $(shell pwd):/data --privileged image-builder-nvidia-shieldtv

shell: build
	docker run --rm -ti -v $(shell pwd):/data --privileged image-builder-nvidia-shieldtv bash

test: build
	docker run --rm -ti -v $(shell pwd):/data --privileged image-builder-nvidia-shieldtv /test.sh

testshell: build
	docker run --rm -ti -v $(shell pwd):/data -v $(shell pwd)/test:/test --privileged image-builder-nvidia-shieldtv bash
