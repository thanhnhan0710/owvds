# Stage 1: Build
FROM ghcr.io/cirruslabs/flutter:stable AS build-env
WORKDIR /app
COPY . .
RUN flutter build web --release

# Stage 2: Run
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80