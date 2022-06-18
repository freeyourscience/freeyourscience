# Increase visibility of untapped OpenAccess potential

![.github/workflows/ci.yaml](https://github.com/freeyourscience/freeyourscience/workflows/.github/workflows/ci.yaml/badge.svg)

This repository contains the frontend (elm) and backend (python) code for [freeyourscience.org](https://freeyourscience.org).

Free Your Science is out to show authors which of their paywalled publications can be re-published open access today for free and how to do it.

## Run it locally for development

### Requirements

- `npm`
- `python3`
- [task](https://taskfile.dev)

You will also need an `.env` file containing the following variables:

- `SHERPA_API_KEY` ([create one here](https://v2.sherpa.ac.uk/cgi/users/login))
- `UNPAYWALL_EMAIL` ([see their documentation](https://unpaywall.org/products/api))

Optionally, if available you can add an `S2_API_KEY` variable for the Semantic Scholar API key.

### Running, testing, linting

```sh
task dev  # install all deps, compile elm and launch service on localhost:8080
task test # run all tests
task lint # run codeformatting and linting
task prod # build Docker images and run service like prod would, but on localhost:8080
```
