#!/bin/bash
#=============================================================================
# Lo script è all'interno di un container
#
# ogni giorno esegue degli script R che interrogano il DBmeteo 
# e aggiornano dei prodotti di consultazione. Poi carica i prodotti su Minio 
#
# 2018/02/06 MR
#=============================================================================
numsec=86400   # 60 * 60 * 24 -> 1 gg

ERRE=/usr/bin/R

CONVENZIONI_R='convenzioni.R'
FILE_CONV_TXT='Convenzioni.txt'
FILE_CONV_PNG='Convenzioni.png'

TEMPOREALE_R='temporeale.R'
FILE_RT='SensoriRT.txt' # Real Time
FILE_B='SensoriB.txt' # Backup

SCHEDESTAZIONI_R='schedestazioni.R'

SECONDS=$numsec

putS3() {
  path=$1
  file=$2
  aws_path=$3
  bucket=$4
  date=$(date -R)
  acl="x-amz-acl:public-read"
  content_type='application/x-compressed-tar'
  string="PUT\n\n$content_type\n$date\n$acl\n/$bucket/$aws_path$file"
  signature=$(echo -en "${string}" | openssl sha1 -hmac "${S3SECRET}" -binary | base64)
  curl -X PUT -T "$path/$file" \
    --progress-bar \
    -H "Host: $S3HOST" \
    -H "Date: $date" \
    -H "Content-Type: $content_type" \
    -H "$acl" \
    -H "Authorization: AWS ${S3KEY}:$signature" \
    "http://$S3HOST/$bucket/$aws_path$file"
}

#
while [ 1 ]
do
# procedi sono se è passato numsec dall'ultimo invio
if [ $SECONDS -ge $numsec ]
then
#
################# CONVENZIONI ###################### 
#
$ERRE --vanilla $FILE_CONV_TXT $FILE_CONV_PNG < $CONVENZIONI_R
# verifico se è andato a buon fine
STATO=$?
echo "STATO USCITA DA "$ $CONVENZIONI_R" ====> "$STATO

if [ "$STATO" -eq 1 ] # se si sono verificate anomalie esci 
then
  exit 1
else # caricamento su MINIO 
putS3 . $FILE_CONV_TXT prodotti/ anagrafica 
putS3 . $FILE_CONV_PNG prodotti/ anagrafica 

# controllo sul caricamento su MINIO 
if [ $? -ne 0 ]
then
  echo "problema caricamento su MINIO"
  exit 1
fi
fi

rm -f $FILE_CONV_TXT
rm -f $FILE_CONV_PNG
#
################# TEMPO REALE SU WEB  ###################### 
#
$ERRE --vanilla $FILE_RT $FILE_B < $TEMPOREALE_R
# verifico se è andato a buon fine
STATO=$?
echo "STATO USCITA DA "$ $TEMPOREALE_R" ====> "$STATO

if [ "$STATO" -eq 1 ] # se si sono verificate anomalie esci
then
  exit 1
else # caricamento su MINIO
putS3 . $FILE_RT prodotti/ anagrafica
putS3 . $FILE_B prodotti/ anagrafica

# controllo sul caricamento su MINIO
if [ $? -ne 0 ]
then
  echo "problema caricamento su MINIO"
  exit 1
fi
fi

rm -f $FILE_RT
rm -f $FILE_B
#
################# SCHEDE STAZIONE  ###################### 
#
$ERRE --vanilla  < $SCHEDESTAZIONI_R
# verifico se è andato a buon fine
STATO=$?
echo "STATO USCITA DA "$ $SCHEDESTAZIONI_R" ====> "$STATO

if [ "$STATO" -eq 1 ] # se si sono verificate anomalie esci
then
  exit 1
else # caricamento su MINIO

#NUMERO_SCHEDE=`ls *_main.html | wc -l`
for x in *_main.html
do
  putS3 . $x prodotti/schedestazioni/ anagrafica
  rm -f $x
done

# controllo sul caricamento su MINIO
if [ $? -ne 0 ]
then
  echo "problema caricamento su MINIO"
  exit 1
fi
fi

# rimuovo file creati dalla funzione R2HTML ma non utili
rm -f *.html   
rm -f R2HTML.css 
rm -f R2HTMLlogo.gif 
#
#######################################################
#
SECONDS=0
#
fi
done
exit 0
