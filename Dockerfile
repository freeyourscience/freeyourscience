FROM tiangolo/uvicorn-gunicorn-fastapi:python3.7@sha256:cae1a92ba5b15c9e92b5b00875fef83fe16d8c7332f30195cc529be879dd3aed

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY . /usr/src/app

RUN pip install --upgrade pip setuptools
RUN pip install --no-cache-dir /usr/src/app

ENV PYTHONPATH=/usr/src/app/wbf