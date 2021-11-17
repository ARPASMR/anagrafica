FROM arpasmr/r-base 
COPY . /usr/local/src/myscripts
WORKDIR /usr/local/src/myscripts
ARG secret
ENV https_proxy=https://${secret}@proxy2.arpa.local:8080/
ENV http_proxy=http://${secret}@proxy2.arpa.local:8080/
#RUN chmod -R 755 /usr/local/src/myscript
CMD ["./anagrafica_IRIS.sh"]
