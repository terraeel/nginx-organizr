FROM certbot/certbot:latest

VOLUME ["/etc/ssl/certs/"]

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

