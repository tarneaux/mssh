FROM alpine:latest

RUN mkdir /keys

RUN apk add --no-cache --upgrade openssh bash
RUN apk add --no-cache rsync unison
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
RUN mkdir /hostkeys
RUN chmod 700 /hostkeys

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

CMD ["/entrypoint.sh"]

VOLUME /hostkeys
VOLUME /keys
VOLUME /home
