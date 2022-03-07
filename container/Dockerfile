FROM ghcr.io/void-linux/void-linux:20220211rc01-thin-x86_64

RUN xbps-install --sync --update --yes && \
    xbps-install --yes findutils git openssh

CMD ["/bin/sh"]
