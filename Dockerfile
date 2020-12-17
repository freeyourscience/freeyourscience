FROM python:alpine as base

WORKDIR /app

COPY requirements.txt requirements.txt
COPY requirements_dev.txt requirements_dev.txt
COPY setup.py /app



FROM base as dev
RUN apk add --no-cache --virtual .build-deps gcc libc-dev make \
    && pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir -r requirements_dev.txt \
    && apk del .build-deps gcc libc-dev make

COPY fyscience /app/fyscience
RUN pip install -e /app

EXPOSE 8080
CMD ["uvicorn", "--reload", "--host", "0.0.0.0", "--port", "8080", "--log-level", "info", "fyscience.main:app"]



FROM base as prod
RUN apk add --no-cache --virtual .build-deps gcc libc-dev make \
    && pip install --no-cache-dir -r requirements.txt \
    && apk del .build-deps gcc libc-dev make

COPY fyscience /app/fyscience
RUN pip install --no-cache /app

COPY gunicorn_conf.py /app
EXPOSE 80
CMD ["gunicorn", "-k", "uvicorn.workers.UvicornWorker", "-c", "gunicorn_conf.py", "fyscience.main:app"]
