from setuptools import setup, find_packages

with open("requirements.txt") as f:
    install_requires = f.read().splitlines()

with open("requirements_dev.txt") as f:
    extras_require = {"dev": f.read().splitlines()}

setup(
    name="fyscience",
    version="0.0.1",
    packages=find_packages(),
    python_requires=">=3.7, <4",
    install_requires=install_requires,
    extras_require=extras_require,
)
