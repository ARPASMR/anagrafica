#!/bin/bash
#===================================================================================================================
# Lo script è all'interno del container e lancia lo script script R "anagrafica_IRIS_DEVEL.R" una volta al giorno 
# Lo script R estrae le info di anagrafica per IRIS "versione DEVEL" dal DBmeteo e 
# le importa nella tabella anagraficasensori del DB postgres iris_devel
#
# 2020/05/12 SGR
# 
#==================================================================================================================
numsec=86400 # 1volta al giorno 24*3600
/usr/bin/Rscript anagrafica_IRIS_DEVEL.R
sleep $numsec
while [ 1 ]
do
  if [ $SECONDS -ge $numsec ]
  then
    /usr/bin/Rscript anagrafica_IRIS_DEVEL.R
    SECONDS=0
    sleep $numsec
  fi
done
