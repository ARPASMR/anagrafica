FROM arpasmr/r-base:latest 
COPY . /usr/local/src/myscripts
WORKDIR /usr/local/src/myscripts
CMD ["./anagrafica_IRIS_DEVEL.sh"]
