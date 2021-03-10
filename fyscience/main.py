import os

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exception_handlers import http_exception_handler
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from starlette.exceptions import HTTPException

from fyscience.routers.api import api_router
from fyscience.routers.html import html_router
from fyscience.routers.deps import TEMPLATE_PATH


STATIC_PATH = os.path.join(os.path.abspath(os.path.dirname(__file__)), "static")

templates = Jinja2Templates(directory=TEMPLATE_PATH)

app = FastAPI(title="Free Your Science")
app.include_router(api_router)
app.include_router(html_router, include_in_schema=False)
app.mount("/static", StaticFiles(directory=STATIC_PATH), name="static")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://localhost:8080",
        "http://localhost:8000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(HTTPException)
async def human_friendly_error_pages(request: Request, exc: HTTPException):
    accept = request.headers["accept"]

    if "text/html" in accept:
        response = templates.TemplateResponse(
            "error.html",
            {"request": request, "detail": exc.detail},
        )
        response.status_code = exc.status_code
        return response

    return await http_exception_handler(request, exc)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8080)
