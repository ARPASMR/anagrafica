FROM arpasmr/r-base
COPY . /usr/local/src/myscripts
WORKDIR /usr/local/src/myscripts
#ENTRYPOINT echo "Fatto"
CMD ["/bin/sh", "-ec", "sleep 300"]
#CMD ["./anagrafica_IRIS_DEVEL.sh"]
