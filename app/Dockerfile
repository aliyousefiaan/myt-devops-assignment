FROM python:3.12.9-alpine

EXPOSE 5000

WORKDIR /app

COPY requirements.txt app.py ./

# No cache to keep the image minimal
RUN pip install --no-cache-dir -r requirements.txt

# Use non root user for security
USER 1000

ENTRYPOINT ["python3", "app.py"]
