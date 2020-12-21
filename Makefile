.PHONY: elm elm-deps build-dev dev lint prod release test

elm-deps:
	npm install elm-test uglify-js -g

elm:
	cd elm_frontend \
	&& elm make src/Main.elm --output authorPapers.raw.js \
	&& uglifyjs authorPapers.raw.js --compress "pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe" | uglifyjs --mangle > authorPapers.js


build-dev:
	docker build . --target dev --cache-from freeyourscience-dev -t freeyourscience-dev

dev: build-dev
	docker run --rm -it -v $$(pwd):/app -p 8080:8080 freeyourscience-dev

test:
	docker run --rm -v $$(pwd):/app freeyourscience-dev pytest

lint:
	docker run --rm freeyourscience-dev black --check .

prod:
	docker build . --target prod -t freeyourscience
	docker run --rm -it -p 8080:80 freeyourscience

release: export TAG = latest/$(shell date +%Y%m%d%H%M)
release:
	git tag $$TAG
	git push origin $$TAG
