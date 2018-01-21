FROM nginx:alpine

LABEL maintainer="Hally"

RUN echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories && \
    apk --no-cache add shadow git bash && \
    usermod -u 82 nginx

# Nginx config files
COPY nginx.conf /etc/nginx/nginx.conf

# SSL files
COPY strong-ssl.conf /etc/nginx/snippets/strong-ssl.conf

# Geoblocking
COPY GeoIP.dat /etc/nginx/GeoIP/GeoIP.dat

COPY --chown=82:82 entrypoint.sh /usr/local/bin

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
