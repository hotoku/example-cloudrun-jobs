import os

print("hello", os.getenv("CLOUD_RUN_TASK_COUNT", "100"), os.getenv("CLOUD_RUN_TASK_INDEX", "0"))
