from setuptools import setup, find_packages

setup(
    name="wbf",
    version="0.0.1",
    packages=find_packages(),
    python_requires=">=3.7, <4",
    install_requires=["requests", "pydantic", "fastapi", "uvicorn", "gunicorn"],
    extras_require={
        "dev": ["black", "pytest", "pytest-cov", "pytest-mock"],
    },
)
