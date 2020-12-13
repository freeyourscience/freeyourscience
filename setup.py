from setuptools import setup, find_packages

setup(
    name="fyscience",
    version="0.0.1",
    packages=find_packages(),
    python_requires=">=3.7, <4",
    install_requires=[
        "requests",
        "pydantic[dotenv]",
        "fastapi",
        "uvicorn",
        "gunicorn",
        "jinja2",
        "aiofiles",
        "uvloop",
        "httptools",
        "loguru",
    ],
    extras_require={
        "dev": ["black", "pytest", "pytest-cov", "pytest-mock"],
    },
)
