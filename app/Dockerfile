ARG PYTHON_VERSION=3.12.9

FROM python:${PYTHON_VERSION}-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

EXPOSE 5000

WORKDIR /app

COPY requirements.txt app.py ./

# No cache to keep the image minimal
RUN pip install --no-cache-dir -r requirements.txt

# Use non root user for security
USER 1000

ENTRYPOINT ["waitress-serve"]

CMD ["--host=0.0.0.0", "--port=5000", "app:app"]
