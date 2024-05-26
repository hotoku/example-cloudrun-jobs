FROM python:3.12.2

COPY main.bash main.bash
COPY main.py main.py

ENTRYPOINT ["./main.bash"]
