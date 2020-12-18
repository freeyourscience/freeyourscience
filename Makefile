.PHONY: dev lint prod test

dev:
	docker build . --target dev -t freeyourscience-dev
	docker run --rm -it -v $$(pwd):/app -p 8080:8080 freeyourscience-dev

test:
	docker build . --target dev -t freeyourscience-dev
	docker run --rm -v $$(pwd):/app freeyourscience-dev pytest

lint:
	docker build . --target dev -t freeyourscience-dev
	docker run --rm freeyourscience-dev black --check .

prod:
	docker build . --target prod -t freeyourscience
	docker run --rm -it -p 8080:80 freeyourscience
