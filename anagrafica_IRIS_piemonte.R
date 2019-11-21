#=================================================================================#
#  estrae le info di anagrafica per IRIS Piemonte dal DBmeteo e le scrive su file # 
#  2018/01/05 MR                                                                  #
#=================================================================================#
#
library(DBI)
library(RMySQL)

# funzione per gestire eventuali errori
neverstop<-function(){
  print("EE..ERRORE durante l'esecuzione dello script!! Messaggio d'Errore prodotto:")
  quit(status=1)
}
options(show.error.messages=TRUE,error=neverstop)

# Leggi riga di comando
arguments <- commandArgs()
file_output<-arguments[6]
print(arguments)

# connessione al DB
drv<-dbDriver("MySQL")
conn<-try(dbConnect(drv, user="guardone", password=as.character(Sys.getenv("MYSQL_PWD")), dbname="METEO", host="10.10.0.19"))

if (inherits(conn,"try-error")) {
  print( "ERRORE nell'apertura della connessione al DB \n")
  print( "chiusura connessione malriuscita ed uscita dal programma \n")
  dbDisconnect(conn)
  rm(conn)
  dbUnloadDriver(drv)
  quit(status=1)
}

# preparazione query
query= paste('select A_Stazioni.IDstazione, IDrete, ProprietaStazione, Provincia, Comune, Attributo, truncate(Y(A_Sensori.CoordUTM),0) as UTM_Nord, truncate(X(A_Sensori.CoordUTM),0) as UTM_Est, QuotaSensore as Quota, A_Sensori.IDsensore, NOMEtipologia, (IFNULL(QSedificio, 0) + IFNULL(QSsupporto,0)) as Altezza , AggregazioneTemporale as Frequenza from  A_Stazioni, A_Sensori, A_Sensori2Destinazione where  A_Stazioni.IDstazione=A_Sensori.IDstazione and  A_Sensori.IDsensore=A_Sensori2Destinazione.IDsensore and A_Sensori2Destinazione.Destinazione=5 and A_Sensori2Destinazione.Datafine is NULL;',sep="")
#
#--------------------------------------------------------------------------------------------
# query in formato più leggibile
#
#'select 
#  A_Stazioni.IDstazione, 
#  IDrete, 
#  ProprietaStazione, 
#  Provincia, 
#  Comune,
#  Attributo,
#  truncate(Y(A_Sensori.CoordUTM),0) as UTM_Nord,
#  truncate(X(A_Sensori.CoordUTM),0) as UTM_Est,
#  QuotaSensore as Quota,
#  A_Sensori.IDsensore,
#  NOMEtipologia, 
#  (IFNULL(QSedificio, 0) + IFNULL(QSsupporto,0)) as Altezza , 
#  AggregazioneTemporale as Frequenza, 
#
#from 
# A_Stazioni,
# A_Sensori, 
# A_Sensori2Destinazione  
#
#where  
# A_Stazioni.IDstazione=A_Sensori.IDstazione and  A_Sensori.IDsensore=A_Sensori2Destinazione.IDsensore 
#
#and 
# A_Sensori2Destinazione.Destinazione=5
#and
# A_Sensori2Destinazione.Datafine is NULL;',sep="") 
#--------------------------------------------------------------------------------------------

# esecuzione query
anagrafica<-try(dbGetQuery(conn,query), silent=TRUE)
write.csv(anagrafica, row.names=FALSE, file_output)

# disconnessione dal DB 
RetCode<-try(dbDisconnect(conn),silent=TRUE)
if (inherits(RetCode,"try-error")) {
  quit(status=1)
}
rm(conn)
dbUnloadDriver(drv)
q()
