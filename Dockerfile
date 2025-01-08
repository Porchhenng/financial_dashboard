FROM ubuntu:20.04

# Set up environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    xz-utils \
    libglu1-mesa

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Set Flutter version to match Dart 3.5.3
RUN git -C /flutter checkout 3.13.7-stable
RUN flutter doctor

# Set the working directory
WORKDIR /app

# Copy project files
COPY . .

# Install dependencies
RUN flutter pub get

# Build Flutter web app
RUN flutter build web

# Use Nginx to serve the web app
FROM nginx:stable-alpine
COPY --from=0 /app/build/web /usr/share/nginx/html

# Expose port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
