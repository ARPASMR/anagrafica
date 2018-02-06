#!/bin/bash
#=============================================================================
# Lo script è all'interno di un container
#
# ogni giorno lancia uno script R che estrae le info di anagrafica dal DBmeteo 
# per i meteogrammi su meteoweb, le scrive su file e carica il file su MINIO
#
# 2018/02/06 MR
#=============================================================================
numsec=86400   # 60 * 60 * 24 -> 1 gg
ERRE=/usr/bin/R
CODICE_R='crea_xml.R'
FILE_ANAGRAFICA='staz_lomb.xml'

SECONDS=$numsec
LOCKFILE='usr/local/src/myscripts/.lock'

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
#logger -is -p user.notice "operazioni su anagrafica concluse" -t "DATI"

while [ 1 ]
do
# procedi sono se è passato un mese dall'ultimo invio
if [ $SECONDS -ge $numsec ]
then
# genero anagrafica
$ERRE --vanilla $FILE_ANAGRAFICA < $CODICE_R
# verifico se è andato a buon fine
STATO=$?
echo "STATO USCITA DA "$ $CODICE_R" ====> "$STATO
# se si sono verificate anomalie (exit status = 1) allora esci ...
if [ "$STATO" -eq 1 ]
then
  exit 1
else
# caricamento su MINIO 
putS3 . $FILE_ANAGRAFICA xml/ anagrafica 

# controllo sul caricamento su MINIO 
if [ $? -ne 0 ]
then
  echo "problema caricamento su MINIO"
  exit 1
fi
fi
#
SECONDS=0
rm -f $FILE_ANAGRAFICA
#
fi
done
exit 0
