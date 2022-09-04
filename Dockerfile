FROM  python:3-alpine
RUN   pip install flask
COPY  . /opt/
WORKDIR /opt
EXPOSE  8080
CMD ["python", "server.py"]
