FROM python:3.12-slim
RUN pip install --no-cache-dir requests==2.32.3
COPY feeder.py /feeder.py
USER nobody
CMD ["python", "-u", "/feeder.py"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD python -c "import os,sys,time; sys.exit(time.time()-os.path.getmtime('/tmp/alive')>900)"
