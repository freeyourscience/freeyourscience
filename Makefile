.PHONY: build-dev dev lint prod test

build-dev:
	docker build . --target dev --cache-from freeyourscience-dev -t freeyourscience-dev

dev: build-dev
	docker run --rm -it -v $$(pwd):/app -p 8080:8080 freeyourscience-dev

test: build-dev
	docker run --rm -v $$(pwd):/app freeyourscience-dev pytest

lint: build-dev
	docker run --rm freeyourscience-dev black --check .

prod:
	docker build . --target prod -t freeyourscience
	docker run --rm -it -p 8080:80 freeyourscience
