FROM python:slim

WORKDIR /app

COPY requirements.txt requirements.txt

COPY web_server/web_server.py .

RUN pip install -r requirements.txt

EXPOSE 5000

CMD ["python", "web_server.py"]