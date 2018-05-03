#==================================================================#
#  estrae le info di anagrafica per IRIS dal DBmeteo e le importa  # 
#  nella tabella anagraficasensori del DB postgres di IRIS         #
#                                                                  #
#  2018/01/05 MR                                                   #
#==================================================================#
#
library(DBI)
library(RMySQL)
library(RPostgreSQL)

# funzione per gestire eventuali errori
neverstop<-function(){
  print("EE..ERRORE durante l'esecuzione dello script!! Messaggio d'Errore prodotto:")
  quit(status=1)
}
options(show.error.messages=TRUE,error=neverstop)

# connessione al DB
drv<-dbDriver("MySQL")
conn<-try(dbConnect(drv, user="guardone", password=as.character(Sys.getenv("MYSQL_PWD")), dbname="METEO", host="10.10.0.6"))

if (inherits(conn,"try-error")) {
  print( "ERRORE nell'apertura della connessione al DBmeteo \n")
  dbDisconnect(conn)
  rm(conn)
  dbUnloadDriver(drv)
  quit(status=1)
}

# preparazione query
query= paste('select A_Stazioni.IDstazione as idstazione, IDrete as idrete, ProprietaStazione as proprieta, Provincia as provincia, Comune as comune, Attributo as attributo, truncate(Y(A_Sensori.CoordUTM),0) as utm_nord, truncate(X(A_Sensori.CoordUTM),0) as utm_est, QuotaSensore as quota, A_Sensori.IDsensore as idsensore, NOMEtipologia as nometipologia,(IFNULL(QSedificio, 0) + IFNULL(QSsupporto,0)) as altezza , AggregazioneTemporale as frequenza, Fiume as fiume, Bacino as bacino,NULL as the_geom, A_Sensori.DataInizio as datainizio, A_Sensori.DataFine as datafine, Storico as storico, NULL as codice_im,CASE WHEN A_Sensori.IDsensore not in (select IDsensore from A_ListaNera where DataFine is NULL) THEN "N" ELSE "S" END AS listanera, CASE WHEN A_Sensori.IDsensore not in (select IDsensore from A_Sensori2Destinazione where Destinazione=13 and DataFine is NULL) THEN "N" ELSE "S" END AS formweb from A_Stazioni, A_Sensori, A_Sensori2Destinazione where  A_Stazioni.IDstazione=A_Sensori.IDstazione and  A_Sensori.IDsensore=A_Sensori2Destinazione.IDsensore and A_Sensori2Destinazione.Destinazione=14 and A_Sensori2Destinazione.Datafine is NULL;',sep="")
#
#--------------------------------------------------------------------------------------------
# stessa query più leggibile (nota:rinomina campi minuscoli perchè postgres non accetta maiuscole)
#
# select 
#   A_Stazioni.IDstazione as idstazione, 
#   IDrete as idrete, 
#   ProprietaStazione as proprieta, 
#   Provincia as provincia, 
#   Comune as comune, 
#   Attributo as attributo, 
#   truncate(Y(A_Sensori.CoordUTM),0) as utm_nord, 
#   truncate(X(A_Sensori.CoordUTM),0) as utm_est, 
#   QuotaSensore as quota, 
#   A_Sensori.IDsensore as idsensore, 
#   NOMEtipologia as nometipologia,
#   (IFNULL(QSedificio, 0) + IFNULL(QSsupporto,0)) as altezza , 
#   AggregazioneTemporale as frequenza, 
#   Fiume as fiume, 
#   Bacino as bacino,
#   NULL as the_geom, 
#   A_Sensori.DataInizio as datainizio, 
#   A_Sensori.DataFine as datafine, 
#   Storico as storico, 
#   NULL as codice_im,
#   CASE 
#    WHEN A_Sensori.IDsensore not in (select IDsensore from A_ListaNera where DataFine is NULL) 
#    THEN "N" ELSE "S" 
#   END AS listanera,
#   CASE 
#    WHEN A_Sensori.IDsensore not in (select IDsensore from A_Sensori2Destinazione where Destinazione=13 and DataFine is NULL) 
#    THEN "N" ELSE "S" 
#   END AS formweb
#
# from  
#  A_Stazioni, 
#  A_Sensori, 
#  A_Sensori2Destinazione 
#
# where 
#  A_Stazioni.IDstazione=A_Sensori.IDstazione and A_Sensori.IDsensore=A_Sensori2Destinazione.IDsensore 
# and 
#  A_Sensori2Destinazione.Destinazione=14 
# and 
#  A_Sensori2Destinazione.Datafine is NULL;
#--------------------------------------------------------------------------------------------

# esecuzione query
anagrafica<-try(dbGetQuery(conn,query), silent=TRUE)

# rimozione caratteri accentati
anagrafica$comune<-iconv(anagrafica$comune,from="ISO-8859-1",to="ASCII//TRANSLIT")
anagrafica$attributo<-iconv(anagrafica$attributo,from="ISO-8859-1",to="ASCII//TRANSLIT")

# disconnessione dal DBmeteo 
RetCode<-try(dbDisconnect(conn),silent=TRUE)
if (inherits(RetCode,"try-error")) {
  quit(status=1)
}
rm(conn)
dbUnloadDriver(drv)


###### DB IRIS
drv_psql<-dbDriver("PostgreSQL")
conn_psql = try(dbConnect(drv_psql, user="postgres", password=as.character(Sys.getenv("PSQL_PWD")), dbname="iris_base", host="10.10.0.19"))
if (inherits(conn_psql,"try-error")) {
  print( "ERRORE nell'apertura della connessione al DB IRIS \n")
  dbDisconnect(conn_psql)
  rm(conn_psql)
  dbUnloadDriver(drv_psql)
  quit(status=1)
}


# svuotamento tabella 
trunc<-try(dbGetQuery(conn_psql,"TRUNCATE dati_di_base.anagraficasensori"), silent=TRUE)
if (inherits(trunc,"try-error")) {
  print( "ERRORE nel svuotare l'anagrafica del DB IRIS \n")
  dbDisconnect(conn_psql)
  rm(conn_psql)
  dbUnloadDriver(drv_psql)
  quit(status=1)
}


# inserimento dati
inserimento<-try(dbWriteTable(conn_psql, c("dati_di_base","anagraficasensori"), anagrafica,append=TRUE,row.names=FALSE),silent=TRUE)
if (inherits(inserimento,"try-error")) {
  print( "ERRORE nel riempire l'anagrafica del DB IRIS \n")
  dbDisconnect(conn_psql)
  rm(conn_psql)
  dbUnloadDriver(drv_psql)
  quit(status=1)
}

# popolamento campi geometrici 
query_update<-paste("UPDATE dati_di_base.anagraficasensori SET the_geom = ST_SetSRID(ST_MakePoint(utm_est, utm_nord), 32632); UPDATE dati_di_base.anagraficasensori SET codice_im = foo.codice_im FROM (SELECT b.codice_im, a.idsensore FROM dati_di_base.anagraficasensori a, dati_di_base.aree_allerta b WHERE st_intersects(a.the_geom, b.the_geom)) AS foo WHERE anagraficasensori.idsensore = foo.idsensore")

update<-try(dbGetQuery(conn_psql,query_update), silent=TRUE)
if (inherits(update,"try-error")) {
  print( "ERRORE nel popolare i campi geometrici dell'anagrafica del DB IRIS \n")
  dbDisconnect(conn_psql)
  rm(conn_psql)
  dbUnloadDriver(drv_psql)
  quit(status=1)
}

# disconnessione dal DB IRIS
RetCode<-try(dbDisconnect(conn_psql),silent=TRUE)
if (inherits(RetCode,"try-error")) {
  quit(status=1)
}
rm(conn_psql)
dbUnloadDriver(drv_psql)

q()
