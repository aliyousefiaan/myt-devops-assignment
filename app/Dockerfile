ARG PYTHON_VERSION=3.12.9

FROM python:${PYTHON_VERSION}-alpine

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

EXPOSE 5000

WORKDIR /app

COPY requirements.txt app.py ./

# No cache to keep the image minimal
RUN pip install --no-cache-dir -r requirements.txt

# Use non root user for security
USER 1000

ENTRYPOINT ["python3", "app.py"]
