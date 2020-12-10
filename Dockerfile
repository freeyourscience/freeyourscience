FROM python:3-alpine

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY . /usr/src/app

RUN apk add build-base
RUN pip install --upgrade pip setuptools
RUN pip install --no-cache-dir /usr/src/app

ENV PYTHONPATH=/usr/src/app/wbf

CMD ["gunicorn", "-w", "1", "-k", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:80", "wbf.main:app"]
