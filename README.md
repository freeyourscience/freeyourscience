# Increase visibility of untapped OpenAccess potential

![.github/workflows/ci.yaml](https://github.com/erkannt/wissenschaftsbefreiungsfront/workflows/.github/workflows/ci.yaml/badge.svg)

This repository contains an exploratory data analysis pipeline to quantify the number of
- paywalled papers that allow but lack OpenAccess author copies
- open access / paywalled papers by author or institution

The hypothesis is, that a significant fraction of scholarly publications that are
currently hidden behind paywalls in fact allow free-of-charge republishing as
OpenAccess.

Should there be evidence for this hypothesis by the above mentioned metrics, the goal is
to create a tool for authors and/or institutions to check which of their papers could be
republished as OpenAccess without additional cost.


## Architecture / Data Flow

![img](./assets/data_flow.png)


## Setup & Test

Install the requirements in a Python 3.7 or 3.8 environment as follows

```
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

and then run the tests with
```
pytest tests/
```
