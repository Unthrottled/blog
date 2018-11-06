FROM alexsimons/jekyll
MAINTAINER Alex Simons "alex@acari.io"
ENV REFRESHED_AT 2017-04-06

ENTRYPOINT [ "jekyll", "serve", "--watch"]
#yolo
