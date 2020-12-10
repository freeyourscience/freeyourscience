FROM tiangolo/uvicorn-gunicorn-fastapi:python3.8-alpine3.10-2020-06-06

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY . /usr/src/app

RUN pip install --upgrade pip setuptools
RUN pip install --no-cache-dir /usr/src/app

ENV PYTHONPATH=/usr/src/app/wbf
