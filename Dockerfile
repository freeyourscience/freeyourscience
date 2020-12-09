FROM python:3-alpine

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY . /usr/src/app

RUN pip install --upgrade pip setuptools
RUN pip install --no-cache-dir /usr/src/app

ENV PYTHONPATH=/usr/src/app/wbf

CMD [ "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80" ]
