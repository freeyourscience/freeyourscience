from setuptools import setup, find_packages

setup(
    name="wbf",
    version="0.0.1",
    packages=find_packages(),
    python_requires=">=3.7, <4",
    install_requires=[
        "requests",
        "pydantic[dotenv]",
        "fastapi",
        "uvicorn",
        "gunicorn",
        "beautifulsoup4",
        "jinja2",
        "aiofiles",
    ],
    extras_require={
        "dev": ["black", "pytest", "pytest-cov", "pytest-mock"],
    },
)
