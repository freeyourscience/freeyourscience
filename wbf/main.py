import os

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
import uvicorn

from wbf.api import api_router


STATIC_PATH = os.path.join(os.path.abspath(os.path.dirname(__file__)), "static")

app = FastAPI()
app.include_router(api_router)
app.mount("/static", StaticFiles(directory=STATIC_PATH), name="static")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
