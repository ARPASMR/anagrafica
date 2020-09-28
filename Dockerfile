FROM arpasmr/r-base 
COPY . /usr/local/src/myscripts
WORKDIR /usr/local/src/myscripts
RUN chmod -R 755 /usr/local/src/myscript
CMD ["./anagrafica_IRIS.sh"]
