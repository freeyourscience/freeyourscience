import os

from fastapi import FastAPI, Request, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from wbf.api import api_router
from wbf.deps import TEMPLATE_PATH


STATIC_PATH = os.path.join(os.path.abspath(os.path.dirname(__file__)), "static")

templates = Jinja2Templates(directory=TEMPLATE_PATH)

app = FastAPI()
app.include_router(api_router)
app.mount("/static", StaticFiles(directory=STATIC_PATH), name="static")


@app.exception_handler(HTTPException)
async def human_friendly_error_pages(request: Request, exc: HTTPException):
    response = templates.TemplateResponse(
        "error.html",
        {"request": request, "detail": exc.detail},
    )
    response.status_code = exc.status_code
    return response


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
