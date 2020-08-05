FROM debian:buster

RUN export DEBIAN_FRONTEND=nointeractive \
\
&& apt-get -q -y update \
&& apt-get -q -y upgrade \
&& apt-get -q -y install samba \
&& apt-get -q -y clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
&& touch /var/lib/samba/registry.tdb

EXPOSE 138 445

COPY samba_entrypoint.sh .

ENTRYPOINT ["./samba_entrypoint.sh"]

CMD ["bash", "-c", "smbd -FS -d 2 < /dev/null"]
