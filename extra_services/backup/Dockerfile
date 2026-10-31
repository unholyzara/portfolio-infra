FROM postgres:16-alpine
RUN apk add --no-cache bash aws-cli
COPY watch.sh upload.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/watch.sh /usr/local/bin/upload.sh
CMD ["watch.sh"]