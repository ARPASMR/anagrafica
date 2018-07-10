#!/bin/bash
#=============================================================================
# Lo script è all'interno di un container
#
# ogni mese lancia uno script R che  estrae le info di anagrafica 
# per IRIS Piemonte dal DBmeteo e le scrive su file.  
#
# poi carica il file sull'ftp dello scambio dati
#
#
# 2018/01/05 MR
#=============================================================================
numsec=864000   # 60 * 60 * 24 * 10 -> 10gg
ERRE=/usr/bin/Rscript
CODICE_R='anagrafica_IRIS_piemonte.R'
FILE_ANAGRAFICA='anag'
FTP=/usr/bin/ncftpput
FTP_SERV=ftp.arpalombardia.it
FTP_USR='arpapiem'

SECONDS=$numsec
LOCKFILE='usr/local/src/myscripts/.lock'

while [ 1 ]
do
# procedi sono se è passato un mese dall'ultimo invio
if [ $SECONDS -ge $numsec ]
then
# genero anagrafica
$ERRE $CODICE_R $FILE_ANAGRAFICA
# verifico se è andato a buon fine
STATO=$?
echo "STATO USCITA DA "$ $CODICE_R" ====> "$STATO
# se si sono verificate anomalie (exit status = 1) allora esci ...
if [ "$STATO" -eq 1 ]
then
  exit 1
else
# ...altrimenti se tutto e' andato benone allora trasferisci
# aggiungo data al nome del file 
FILE_ANAGRAFICA_CON_DATA=$FILE_ANAGRAFICA"_"`date +%Y%m%d`".csv"
mv $FILE_ANAGRAFICA $FILE_ANAGRAFICA_CON_DATA
# connessione ftp e trasferimento
$FTP -u $FTP_USR -p $FTP_PWD $FTP_SERV . $FILE_ANAGRAFICA_CON_DATA 
# controllo sulla connessione ftp 
if [ $? -ne 0 ]
then
  echo "problema su connessione ftp"
  exit 1
fi
fi
#
SECONDS=0
rm -f $FILE_ANAGRAFICA_CON_DATA
#
fi
done
exit 0
