FROM arpasmr/r-base 
COPY . /usr/local/src/myscripts
WORKDIR /usr/local/src/myscripts
#CMD ["./anagrafica_IRIS.sh"]

## Test per vedere che il container e' stato creato:
CMD ["/bin/echo", "Creato il container anagrafica_IRIS_lomb"]
## Escamotage per tenere attivo/vivo il container per 5 minuti (300sec) per entrare nel container e fare dei test
CMD ["/bin/sh", "-ec", "sleep 300"]
