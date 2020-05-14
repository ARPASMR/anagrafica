FROM arpasmr/r-base
COPY . /usr/local/src/myscripts
WORKDIR /usr/local/src/myscripts

## Test per vedere che il container e' stato creato:
#CMD ["/bin/echo", "Hello world"]

## Escamotage per tenere attivo/vivo il container per 5 minuti (300sec) per entrare nel container e fare dei test
#CMD ["/bin/sh", "-ec", "sleep 300"]

CMD ["./anagrafica_IRIS_DEVEL.sh"]
