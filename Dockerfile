FROM tiangolo/uvicorn-gunicorn-fastapi:python3.7@sha256:cae1a92ba5b15c9e92b5b00875fef83fe16d8c7332f30195cc529be879dd3aed

COPY . /app

RUN pip install /app
