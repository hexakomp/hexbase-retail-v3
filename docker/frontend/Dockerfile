FROM ghcr.io/cirruslabs/flutter:stable AS build

ARG API_BASE_URL=http://localhost:8080/api

WORKDIR /app

# Copy pubspec files first for layer caching
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Copy rest of source
COPY . .

# Build Flutter web (release)
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ── Production stage: serve with nginx ───────────────────────────────────
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

# Simple nginx config for SPA
RUN printf 'server {\n\
    listen 80;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80
