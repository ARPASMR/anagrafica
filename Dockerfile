FROM registry.arpa.local/base/r-base_arpa 
COPY . /usr/local/src/myscripts
WORKDIR /usr/local/src/myscripts
CMD ["./anagrafica_IRIS_piemonte.sh"]
