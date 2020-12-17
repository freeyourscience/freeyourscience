.PHONY: build dev

build:
	docker build . -t freeyourscience

dev:
	docker run --rm -it -p 8080:80 freeyourscience
