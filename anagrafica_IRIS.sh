#!/bin/bash
#=============================================================================
# Lo script è all'interno del container e lancia uno script R ogni 4h. 
# Lo script R estrae le info di anagrafica per IRIS dal DBmeteo e le importa 
# nella tabella anagraficasensori del DB postgres di IRIS. 
#
# 2018/01/05 MR
# 
#=============================================================================
numsec=3600 # 1 ore 
/usr/bin/Rscript anagrafica_IRIS.R
sleep $numsec
while [ 1 ]
do
  if [ $SECONDS -ge $numsec ]
  then
    /usr/bin/Rscript anagrafica_IRIS.R
    SECONDS=0
    sleep $numsec
  fi
done
