# R script
#==============================================================================
# <crea_xml.R>
# Descrizione:
#  creazione file .xml per display dei punti stazione su Google Maps per 
#  visualizzazione meteogrammi
#
# data      nota
# ----      ----
# 2011/06      MR Prima stesura
# 2015/11      MR aggiornamento ai nomi stazione dati da Comune+Attributo
# 2018/02      MR modificato per calcolo lat lon da utm e inserimento in container docker 
#==============================================================================

library(DBI)
library(RMySQL)
library(rgdal)

# funzione per gestire eventuali errori
neverstop<-function(){
  print("EE..ERRORE durante l'esecuzione dello script!! Messaggio d'Errore prodotto:")
}
options(show.error.messages=TRUE,error=neverstop)

# Leggi riga di comando
arguments <- commandArgs()
file_out <- arguments[3]

    cat("<!-- creata il ", date(), " dal programma crea_staz_lomb.R-->\n", file=file_out)
    cat( '<markers>\n', file=file_out, append=T)

#___________________________________________________
#    COLLEGAMENTO AL DB
#___________________________________________________
#cat ("collegamento al DB\n\n", file=file_log, append=T)
drv<-dbDriver("MySQL")
conn<-try(dbConnect(drv, user="guardone", password=as.character(Sys.getenv("MYSQL_PWD")), dbname="METEO", host="10.10.0.6"))

if (inherits(conn,"try-error")) {
  print( "ERRORE nell'apertura della connessione al DBmeteo \n")
  dbDisconnect(conn)
  rm(conn)
  dbUnloadDriver(drv)
  quit(status=1)
}

#   ELABORAZIONI 
#__________________________________________________
# Richiesta ID stazioni d'interesse
query_staz <- "select distinct(IDstazione) from A_Sensori, A_Sensori2Destinazione where A_Sensori.IDsensore=A_Sensori2Destinazione.IDsensore and Destinazione =12 and A_Sensori2Destinazione.DataFine is null "
staz <- try(dbGetQuery(conn, query_staz),silent=TRUE)
if (inherits(staz,"try-error")) {
  print(paste(staz,"\n",sep=""))
  quit(status=1)
}
# Richiesta altre info di anagrafica
query <- "select A_Stazioni.IDstazione,Comune,Attributo,Quota,X(A_Stazioni.CoordUTM) as UTM_E,Y(A_Stazioni.CoordUTM) as UTM_N, NOMEtipologia ,A_Sensori.IDsensore from A_Sensori , A_Stazioni , A_Sensori2Destinazione where A_Stazioni.IDstazione=A_Sensori.IDstazione and A_Sensori.IDsensore=A_Sensori2Destinazione.IDsensore and Destinazione =12 and A_Sensori2Destinazione.DataFine is null"

anag <- try(dbGetQuery(conn, query),silent=TRUE)
if (inherits(anag,"try-error")) {
  print(paste(anag,"\n",sep=""))
  quit(status=1)
} 

i <- 1
IDstazione <- ""
Comune    <- ""
Attributo    <- ""
lat        <- ""
lon        <- ""
Quota      <- ""

 while (i<length(staz$IDstazione)+1){
IDstazione <- staz$IDstazione[i]
j<- which(anag$IDstazione == IDstazione)
## controllo che la stazione sia dotata di coordinate
if(is.na(anag$UTM_E[j[1]])==F && is.na(anag$UTM_N[j[1]])==F){
 jj<-1
 sens<- ""
 while (jj<(length(j)+1)){
   tip<-anag$NOMEtipologia[j[jj]]
   if(is.na(tip)==TRUE){
     cat("atttenzione!! stazione con ID ",anag$IDstazione[j[jj]], " ha sensore con tipologia indefinita\n")
   }else{
#
    if(tip=="TV" | tip=="T")tip="T"
    if(tip=="PP" | tip=="PPR")tip="R"
    if(tip=="PA")tip="P"
    if(tip=="DV" | tip=="DVQ" | tip=="DVS" | tip=="DVP")tip="D"
    if(tip=="VV" | tip=="VVQ" | tip=="VVS" | tip=="VVP")tip="V"
    if(tip=="RG")tip="G"
    if(tip=="RN")tip="N"
    if(tip=="UR")tip="U"
   }
  sens <- paste(sens,tip,sep="") 
  jj <- jj + 1
 }

anag$Comune[j[1]] <-  iconv(anag$Comune[j[1]],"latin1","UTF-8")
anag$Attributo[j[1]] <-  iconv(anag$Attributo[j[1]],"latin1","UTF-8")

anag$Comune[j[1]] <- sub(' +$', '', anag$Comune[j[1]]) ## trim degli spazi 
anag$Attributo[j[1]] <- sub(' +$', '', anag$Attributo[j[1]]) ## trim degli spazi 

if(is.na(anag$Attributo[j[1]])==TRUE){
 NomeCompleto<-anag$Comune[j[1]]
}else{
 NomeCompleto<-paste(anag$Comune[j[1]], anag$Attributo[j[1]],sep=" ")
}
    # trasformazione UTM -> lat lon
    SP<-SpatialPoints(cbind(anag$UTM_E[j[1]],anag$UTM_N[j[1]]),proj4string=CRS("+proj=utm +zone=32"))
    latlon <- spTransform(SP, CRS("+proj=longlat"))
    lat <- latlon$coords.x2 
    lon <- latlon$coords.x1
    # scrittura su file
    cat(rbind( '<marker idstaz="', IDstazione,'"  ',
              'nome="', NomeCompleto,'"  ',
              'lat="', lat , '"  ', 
              'lon="', lon , '"  ', 
              'quota="', anag$Quota[j[1]], '"  ', 
              'sens="', sens,'"  />',
               '\n'),file=file_out,sep="",append=T)
}else{
 cat("Attenzione, stazione con nome=", NomeCompleto, " e ID=", anag$IDstazione[j[1]], "e j[1]=", j[1], " senza coordinate!!\n")
}
 if(is.na(NomeCompleto)==T) cat("Attenzione, stazione con ID=", anag$IDstazione[j[1]], "e j[1]=", j[1]," senza nome\n")
  i<-i+1
}

cat( '</markers>\n', file=file_out, append=T)
#___________________________________________________
#    DISCONNESSIONE DAL DB
#___________________________________________________

# chiudo db
cat ( "\nchiudo DB \n" )
dbDisconnect(conn)
rm(conn)
dbUnloadDriver(drv)

cat( paste("PROGRAMMA ESEGUITO CON SUCCESSO alle ", date()," \n" ) )
quit()

