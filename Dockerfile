FROM alexsimons/jekyll
LABEL author="Alex Simons 'alexsimons9999@gmail.com'"
ENV REFRESHED_AT 2017-04-06

ENTRYPOINT [ "jekyll", "serve", "--watch"]

