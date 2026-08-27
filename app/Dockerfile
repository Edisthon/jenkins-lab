# Stage 1: Base image
FROM python:3.9-slim AS base
WORKDIR /usr/src/app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# Stage 2: Test image
FROM base AS test
# We run pytest during the image build itself!
RUN pytest test_app.py

# Stage 3: Production image
FROM base AS production
EXPOSE 80
ENTRYPOINT [ "python" ]
CMD ["app.py"]
