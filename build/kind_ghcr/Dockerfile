# — Stage 1: base layer
FROM busybox AS base

# — Stage 2: final runtime image
FROM base AS final

# 1. Create a simple web root
RUN mkdir -p /www

# 2. Add our “page” with just the version text
RUN echo 'Version: v1.0.0' > /www/index.html

# 3. Expose port 8080
EXPOSE 8080

# 4. Launch BusyBox HTTPD in foreground, serving /www on 8080
CMD ["httpd", "-f", "-v", "-p", "8080", "-h", "/www"]
