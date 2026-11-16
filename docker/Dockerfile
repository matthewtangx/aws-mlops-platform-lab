# Base image pinned by digest (python:3.12-slim-bookworm). Update deliberately.
FROM python:3.12-slim-bookworm@sha256:935c3c5b12357a7e10caa9c1e6ca5692344d97cf229832ef584be2cec9fc03df

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY src/ ./src/
ENV PYTHONPATH=/app/src

# Recorded in the image so the artifacts path (models/<git-sha>/) matches the image tag.
ARG GIT_SHA
ENV GIT_SHA=${GIT_SHA}

RUN useradd --system --no-create-home trainer
USER trainer

CMD ["python", "-m", "training"]
