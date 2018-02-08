###############################################
##   estrazione dal DBmeteo dell'elenco e scadenze convenzioni RRQA 
#    per gestione ARPA di stazioni private 
##   Output su txt e png 
##   MR 2015
##   MR 2018 # modificato per uso in container docker 
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
fileoutpng <- arguments[4]

# [] COLLEGAMENTO AL DB
drv<-dbDriver("MySQL")
conn<-try(dbConnect(drv, user="guardone", password=as.character(Sys.getenv("MYSQL_PWD")), dbname="METEO", host="10.10.0.6"))

if (inherits(conn,"try-error")) {
  print( "ERRORE nell'apertura della connessione al DBmeteo \n")
  dbDisconnect(conn)
  rm(conn)
  dbUnloadDriver(drv)
  quit(status=1)
}

#### definisco limiti del grafico
query_richiestaLIM<-"select min(Stipula),max(Scadenza) from A_Convenzioni where Stipula!='0000-00-00' and Scadenza!='0000-00-00';"
    q_richiestaLIM <- try(dbGetQuery(conn, query_richiestaLIM),silent=TRUE)
    if (inherits(q_richiestaLIM,"try-error")) {
      quit(status=1)
    }

datainizio<-as.Date(q_richiestaLIM[,1])
datafine<-as.Date(q_richiestaLIM[,2])
######

 query_richiestaID<-"select distinct(IDstazione) from A_Convenzioni;" 
    q_richiestaID <- try(dbGetQuery(conn, query_richiestaID),silent=TRUE)
    if (inherits(q_richiestaID,"try-error")) {
      quit(status=1)
    }
IDstazioni_conv<-q_richiestaID[,1]
#
# elimino da IDstazioni le stazioni storiche
 query_richiesta<-"select A_Stazioni.IDstazione from A_Sensori, A_Stazioni where A_Stazioni.IDstazione=A_Sensori.IDstazione and Storico='no'" 
print(query_richiesta)
    q_richiesta <- try(dbGetQuery(conn, query_richiesta),silent=TRUE)
    if (inherits(q_richiesta,"try-error")) {
      quit(status=1)
    }
IDstazioni_attive<-q_richiesta[,1]
IDstazioni<-intersect(IDstazioni_conv,IDstazioni_attive)
Nstazioni<-length(IDstazioni)
#
png(file=fileoutpng, width = 1500, height = 1500, )
matrice<-seq(1,Nstazioni,by=1)
nf<-layout(matrix(matrice,Nstazioni,1))
layout.show(nf)
par(mai=c(0.1,0.5,0.4,1))  #dimensioni riquadro primo grafico

staz<-1
while(staz<Nstazioni+1){
    cat("stazione numero ",staz, " con ID=", IDstazioni[staz],"\n")

    query_richiestaCONV<-paste(" select Comune, Attributo,ProprietaStazione, Stipula , Scadenza from A_Convenzioni , A_Stazioni where A_Stazioni.IDstazione=A_Convenzioni.IDstazione and Stipula is not NULL and Stipula !='0000-00-00' and A_Stazioni.IDstazione= ", IDstazioni[staz],";",sep="") 
    q_richiestaCONV <- try(dbGetQuery(conn, query_richiestaCONV),silent=TRUE)
    if (inherits(q_richiestaCONV,"try-error")) {
      quit(status=1)
    }
    IDstazione= IDstazioni[staz]
    Comune=q_richiestaCONV$Comune[1] 
    Attributo=q_richiestaCONV$Attributo[1] 
    Proprieta=q_richiestaCONV$ProprietaStazione[1] 
    Stipula=q_richiestaCONV$Stipula
    Scadenza=q_richiestaCONV$Scadenza
#
    titolo<-paste(IDstazione,Comune, Attributo,Proprieta,sep=" - ")
     plot(datainizio,1,type="n",main=titolo ,adj=0,cex.main=1.4,ylim=c(0,2),xlim=c(datainizio,datafine),xlab="",ylab="",yaxt='n',cex.axis=1.5)
     abline(v= seq(as.Date("2009-01-01"),datafine,by='year'), col="gray",lwd=2) 
    #
    conv<-1
    while(conv<length(Stipula)+1){
    if(IDstazione==598){
     lines(c(as.Date(Stipula[conv]),as.Date(Scadenza[conv])),c(1,1),lwd=8, col="red")
    }else{
     lines(c(as.Date(Stipula[conv]),as.Date(Scadenza[conv])),c(1,1),lwd=8)
    }
    conv<-conv+1
    }
    abline(v=Sys.Date(), col="red",lwd=5) 

staz<-staz+1
}
#################   scrivo su file elenco stazioni non ARPA (solo attive)
print("#################   scrivo su file elenco stazioni non ARPA (solo attive)")
query<-"select Provincia,A_Stazioni.IDstazione ,Comune, Attributo , ProprietaStazione , Manutenzione from A_Stazioni,A_Sensori where A_Stazioni.IDstazione=A_Sensori.IDstazione and ProprietaStazione !='ARPA Lombardia' and IDrete in (1,2,4) and Storico='no' group by A_Stazioni.IDstazione order by Provincia, Comune ;"
    q_richiesta <- try(dbGetQuery(conn, query),silent=TRUE)
    if (inherits(q_richiesta,"try-error")) {
      quit(status=1)
    }
Provincia<-q_richiesta$Provincia
IDstazione<-q_richiesta$IDstazione
Comune<-q_richiesta$Comune
Attributo<-q_richiesta$Attributo
Proprieta<-q_richiesta$ProprietaStazione
Manutenzione<-q_richiesta$Manutenzione
  cat(rbind(sprintf("%3s" , 'PROV')        ," ",
            sprintf("%5s" , 'ID')          ," ",
            sprintf("%25s", 'COMUNE')      ," ",
            sprintf("%20s", 'ATTRIBUTO')   ," ",
            sprintf("%20s", 'PROPRIETA')   ," ",
            sprintf("%20s", 'MANUTENZIONE')," ",
            "\n"),file=fileout)
ii<-1
 while(ii<length(Provincia)+1){
  if(is.na(Attributo[ii])==TRUE)Attributo[ii]<-""
  if(is.na(Manutenzione[ii])==TRUE)Manutenzione[ii]<-""
  cat(rbind(sprintf("%3s" , Provincia[ii])  ," ",
            sprintf("%5i" ,IDstazione[ii])  ," ",
            sprintf("%25s",Comune[ii])      ," ",
            sprintf("%20s",Attributo[ii])   ," ",
            sprintf("%20s",Proprieta[ii])   ," ",
            sprintf("%20s",Manutenzione[ii])," ",
            "\n"),file=fileout,append=T)
  ii<-ii+1
 }

#___________________________________________________
#    DISCONNESSIONE DAL DB
#___________________________________________________
# chiudo db
RetCode<-try(dbDisconnect(conn),silent=TRUE)
if (inherits(RetCode,"try-error")) {
  quit(status=1)
}
rm(conn)
dbUnloadDriver(drv)
q()

