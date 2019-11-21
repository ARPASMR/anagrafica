###############################################
##   estrazione dal DBmeteo dell'elenco sensori pubblicati in tabella tempo reale su WEB
##   e sull'APP Meteo e dell'elenco dei sensori di backup
##  
##   MR 02/11/2017
##   MR 08/02/2018 # modificato per uso in container docker
###############################################
library(DBI)
library(RMySQL)
#..............................................................................
# Gestione di eventuali errori
neverstop<-function(){
  print("EE..ERRORE durante l'esecuzione dello script!! Messaggio d'Errore prodotto:")
  quit()
}
options(show.error.messages=TRUE,error=neverstop,digits=20)
#==============================================================================
# Leggi riga di comando
arguments <- commandArgs()
fileout <- arguments[3]
fileout_b <- arguments[4]

# [] COLLEGAMENTO AL DB
drv<-dbDriver("MySQL")
conn<-try(dbConnect(drv, user="guardone", password=as.character(Sys.getenv("MYSQL_PWD")), dbname="METEO", host="10.10.0.19"))
#
#### sensori pubblicati
query_richiestaT<-"select Provincia, A_Sensori.IDsensore , CONCAT(Comune,' ',IFNULL(Attributo,'')) as Nome , NOMEtipologia from A_Sensori, A_Sensori2Destinazione, A_Stazioni where A_Sensori.IDstazione =A_Stazioni.IDstazione and A_Sensori.IDsensore =A_Sensori2Destinazione.IDsensore and Destinazione =3 and A_Sensori2Destinazione.DataFine is NULL order by Provincia, Nome, NOMEtipologia;"
    q_richiestaT <- try(dbGetQuery(conn, query_richiestaT),silent=TRUE)
    if (inherits(q_richiestaT,"try-error")) {
      quit(status=1)
    }
#
#### sensori di backup 
query_richiestaB<-"select Provincia, A_Sensori.IDsensore , CONCAT(Comune,' ',IFNULL(Attributo,'')) as Nome, NOMEtipologia from A_Sensori, A_Sensori2Destinazione, A_Stazioni where A_Sensori.IDstazione =A_Stazioni.IDstazione and A_Sensori.IDsensore =A_Sensori2Destinazione.IDsensore and Destinazione =4 and A_Sensori2Destinazione.DataFine is NULL order by Provincia, Nome, NOMEtipologia;"
    q_richiestaB <- try(dbGetQuery(conn, query_richiestaB),silent=TRUE)
    if (inherits(q_richiestaB,"try-error")) {
      quit(status=1)
    }


#################   scrivo su file elenco sensori pubblicati

ProvinciaT<-q_richiestaT$Provincia
IDsensoreT<-q_richiestaT$IDsensore
NomeT<-q_richiestaT$Nome
NOMEtipologiaT<-q_richiestaT$NOMEtipologia
cat("\nSENSORI PUBBLICATI IN TABELLA TEMPO REALE SU WEB E SU APP\n\n",file=fileout)
  cat(rbind(sprintf("%4s" , 'PROV')        ," ",
            sprintf("%5s" , 'ID')          ," ",
            sprintf("%35s", 'NOME')        ," ",
            sprintf("%2s", 'TIPOLOGIA')    ," ",
            "\n"),file=fileout, append=T)
ii<-1
 while(ii<length(ProvinciaT)+1){
  if (ii>1 && ProvinciaT[ii]!=ProvinciaT[ii-1])cat("\n",file=fileout,append=T)
  cat(rbind(sprintf("%4s" , ProvinciaT[ii])    ," ",
            sprintf("%5i" ,IDsensoreT[ii])     ," ",
            sprintf("%35s",NomeT[ii])          ," ",
            sprintf("%2s",NOMEtipologiaT[ii])  ," ",
            "\n"),file=fileout,append=T)
  ii<-ii+1
 }
#
#################   scrivo su file elenco sensori di backup
ProvinciaB<-q_richiestaB$Provincia
IDsensoreB<-q_richiestaB$IDsensore
NomeB<-q_richiestaB$Nome
NOMEtipologiaB<-q_richiestaB$NOMEtipologia
cat("\n\nSENSORI DI BACKUP\n\n",file=fileout_b)
  cat(rbind(sprintf("%4s" , 'PROV')        ," ",
            sprintf("%5s" , 'ID')          ," ",
            sprintf("%35s", 'NOME')        ," ",
            sprintf("%2s", 'TIPOLOGIA')    ," ",
            "\n"),file=fileout_b, append=T)
ii<-1
 while(ii<length(ProvinciaB)+1){
  if (ii>1 && ProvinciaB[ii]!=ProvinciaB[ii-1])cat("\n",file=fileout_b,append=T)
  cat(rbind(sprintf("%4s" , ProvinciaB[ii])    ," ",
            sprintf("%5i" ,IDsensoreB[ii])     ," ",
            sprintf("%35s",NomeB[ii])          ," ",
            sprintf("%2s",NOMEtipologiaB[ii])  ," ",
            "\n"),file=fileout_b,append=T)
  ii<-ii+1
 }
#___________________________________________________
#    DISCONNESSIONE DAL DB
#___________________________________________________
RetCode<-try(dbDisconnect(conn),silent=TRUE)
if (inherits(RetCode,"try-error")) {
  quit(status=1)
}
rm(conn)
dbUnloadDriver(drv)
q()

