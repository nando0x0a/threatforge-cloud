FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN pip install --no-cache-dir requests==2.32.3

COPY notifier.py provision_channel.py ./

CMD ["python3", "notifier.py"]
