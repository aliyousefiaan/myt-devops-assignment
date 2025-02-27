FROM python:3.12.9-alpine

EXPOSE 5000

WORKDIR /app

COPY requirements.txt app.py ./

RUN pip install --no-cache-dir -r requirements.txt

USER 1000

ENTRYPOINT ["python3", "app.py"]
