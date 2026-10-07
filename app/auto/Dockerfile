FROM python:3.12-slim
RUN pip install --no-cache-dir requests==2.32.3
COPY feeder.py /feeder.py
USER nobody
CMD ["python", "-u", "/feeder.py"]
