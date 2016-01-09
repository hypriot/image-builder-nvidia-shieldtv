default: build

build:
	docker build -t image-builder-nvidia-shieldtv .

sd-image: build
	docker run --rm --privileged -v $(shell pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules image-builder-nvidia-shieldtv

shell: build
	docker run -ti --privileged -v $(shell pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules image-builder-nvidia-shieldtv bash
