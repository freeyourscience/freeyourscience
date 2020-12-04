from setuptools import setup, find_packages
import pathlib

setup(
    name="wbf",
    version="0.0.1",
    packages=find_packages(),
    python_requires=">=3.7, <4",
    install_requires=["requests"],
    extras_require={
        "dev": ["black", "pytest", "pytest-cov"],
    },
)
