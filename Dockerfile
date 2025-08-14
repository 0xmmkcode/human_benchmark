# ---------- Stage 1: Build Flutter web ----------
    FROM ghcr.io/cirruslabs/flutter:stable AS build
    WORKDIR /app
    
    # Cache pub dependencies
    COPY pubspec.yaml pubspec.lock ./
    RUN flutter pub get
    
    # Copy the rest and build
    COPY . .
    # If your web entrypoint is at lib/web/main.dart, keep the -t flag below
    RUN flutter build web --release -t lib/web/main.dart
    
    # ---------- Stage 2: Serve with Nginx ----------
    FROM nginx:1.27-alpine
    # Optional: replace default server with an SPA-friendly config
    # COPY nginx.conf /etc/nginx/conf.d/default.conf
    
    # Static site
    COPY --from=build /app/build/web /usr/share/nginx/html
    
    EXPOSE 80
    HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost/ || exit 1
    
    CMD ["nginx", "-g", "daemon off;"]