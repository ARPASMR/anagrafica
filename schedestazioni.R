#==============================================================================
##   estrazione dal DBmeteo delle info di anagrafica e creazione delle  
##   schede stazione con foto e ortofoto in formato hmtl 
##   come da modulo MO.SI.014
##
##   MR 2013
##   MR 08/02/2018 # modificato per uso in container docker
#==============================================================================
library(DBI)
library(RMySQL)
library(R2HTML)

#==============================================================================
#+ gestione dell'errore
neverstop<-function(){
  print("EE..ERRORE durante l'esecuzione dello script!! Messaggio d'Errore prodotto:\n")
  quit()
}
options(show.error.messages=TRUE,error=neverstop)

#==============================================================================
#apro connessione con il db
drv<-dbDriver("MySQL")
conn<-try(dbConnect(drv, user="guardone", password=as.character(Sys.getenv("MYSQL_PWD")), dbname="METEO", host="10.10.0.19"))
if (inherits(conn,"try-error")) {
  print( "ERRORE nell'apertura della connessione al DBmeteo \n")
  print( " chiusura connessione malriuscita ed uscita dal programma \n")
  dbDisconnect(conn)
  rm(conn)
  dbUnloadDriver(drv)
  quit(status=1)
}

#------------------------------------------------------------------------------
# interroga DB su info stazioni 
q_dbmeteo <- NULL
query<- paste("select * from A_Stazioni")
q_dbmeteo <- try(dbGetQuery(conn,query),silent=TRUE)
if (inherits(q_dbmeteo,"try-error")) {
  print( "ERRORE nell'esecuzione query \n")
  dbDisconnect(conn)
  rm(conn)
  dbUnloadDriver(drv)
  quit(status=1)
}

# ciclo sulle stazioni
i<-1
while (i<=length(q_dbmeteo$IDstazione)) {
#HTMLStart(outdir="/srv/www/htdocs/applications/schedestazioni", 
HTMLStart(outdir=".", 
          file=q_dbmeteo$IDstazione[i],  
          extension="html", 
#         echo=FALSE, 
          HTMLframe=TRUE)

HTMLInsertGraph("LOGO_ARPA_low.jpg",
                Caption="Servizio Meteorologico Regionale", 
                GraphBorder=1, 
                Align="right",
                WidthHTML=200, 
                HeightHTML=NULL)

HTML.title(paste("<b>",q_dbmeteo$Comune[i] ," ",q_dbmeteo$Attributo[i] ,sep=""), HR=1)

#HTML.title("STAZIONE", HR=3)

#GENERICHE
IDstazione<-paste("<b>",q_dbmeteo$IDstazione[i],sep="")
NOMEbreve <-paste("<b>",q_dbmeteo$NOMEbreve[i] ,sep="")
LOC       <-paste("<b>",q_dbmeteo$Localita[i]  ,sep="")
COM       <-paste("<b>",q_dbmeteo$Comune[i]    ,sep="")
PR        <-paste("<b>",q_dbmeteo$Provincia[i] ,sep="")
NOME      <-paste("<b>",q_dbmeteo$Comune[i] ," ",q_dbmeteo$Attributo[i] ,sep="")
#
NOME
a<-c("IDstazione:",IDstazione,"NOME:"     ,NOME)
b<-c("NOMEbreve:" ,NOMEbreve ,"Comune:"   ,COM )
c<-c("Localita:"  ,LOC       ,"Provincia:",PR  )
#
x<-data.frame(a,b,c)
x<-t(x)
HTML(x,  Border = 5, innerBorder=1,align="left",caption = "", captionalign = "top")

# COORDINATE e QUOTA
QUOTA<-paste("<b>",q_dbmeteo$Quota[i]   ,sep="")
CGBN <-paste("<b>",q_dbmeteo$CGB_Nord[i],sep="")
CGBE <-paste("<b>",q_dbmeteo$CGB_Est[i] ,sep="")
LAT  <-paste("<b>",q_dbmeteo$lat[i]     ,sep="")
LON  <-paste("<b>",q_dbmeteo$lon[i]     ,sep="")
UTMN <-paste("<b>",q_dbmeteo$UTM_Nord[i],sep="")
UTME <-paste("<b>",q_dbmeteo$UTM_Est[i] ,sep="")
#
a<-c("Quota amsl:",QUOTA, ""            , ""  )
b<-c("CGB_Nord:"  ,CGBN , "CGB_Est:"    , CGBE)
c<-c("Latitudine:",LAT  , "Longitudine:", LON )
d<-c("UTM_Nord:"  ,UTMN , "UTM_Est:"    ,UTME )
#
x<-data.frame(a,b,c,d)
x<-t(x)
x<-gsub("NA"," - ", x) 
x<-gsub("NULL"," - ", x) 
HTML(x,  Border = 5, innerBorder=1,align="left",caption = "QUOTA E COORDINATE", captionalign = "top")

# CLASSIFICAZIONI
AL <-paste("<b>",q_dbmeteo$Allerta[i]    ,sep="")
PVM<-paste("<b>",q_dbmeteo$PVM[i]        ,sep="")
DUS<-paste("<b>",q_dbmeteo$LandUse[i]    ,sep="")
UW <-paste("<b>",q_dbmeteo$UrbanWeight[i],sep="")
#
a<-c("Area di allerta Protezione Civile:",AL , "Classificazione PianuraValleMontagna:", PVM)
b<-c("Uso del Suolo (DUSAF):"            ,DUS, "Coefficiente Frazione Urbana:"        , UW )
#
x<-data.frame(a,b)
x<-t(x)
x<-gsub("NA"," - ", x) 
x<-gsub("NULL"," - ", x) 
HTML(x,  Border = 5, innerBorder=1,align="left",caption = "CLASSIFICAZIONI", captionalign = "top")


# Proprietà e eventuali convenzioni 
PS<-paste("<b>",q_dbmeteo$ProprietaStazione[i],sep="")
a<-c("Proprietà Stazione:",PS)
x<-data.frame(a)
x<-t(x)
x<-gsub("NA"," - ", x) 
x<-gsub("NULL"," - ", x) 
HTML(x,  Border = 5, innerBorder=1,align="left",row.names="FALSE")

if(q_dbmeteo$ProprietaStazione[i]!="ARPA Lombardia" & is.na(q_dbmeteo$ProprietaStazione[i])==F){
 # interroga DB su info convenzioni 
 q_convenzioni <- NULL
 stringa<-paste("select * from A_Convenzioni where IDstazione=",q_dbmeteo$IDstazione[i],sep="")
 q_convenzioni <- try(dbGetQuery(conn, stringa),silent=TRUE)
 if (inherits(q_dbmeteo,"try-error")) {
   print( "ERRORE nell'esecuzione query \n")
   dbDisconnect(conn)
   rm(conn)
   dbUnloadDriver(drv)
   quit(status=1)
 }
 conv<-1
 while (conv<=length(q_convenzioni$IDstazione)) {
  ST<-paste("<b>",q_convenzioni$Stipula[conv]   ,sep="")
  SC<-paste("<b>",q_convenzioni$Scadenza[conv]   ,sep="")
  CA<-paste("<b>",q_convenzioni$CodiceArch[conv],sep="")
  a<-c("Stipula Convenzione:",ST,"Scadenza:",SC,"Codice Archiviazione:",CA)
  x<-data.frame(a)
  x<-t(x)
  x<-gsub("NA"," - ", x) 
  x<-gsub("NULL"," - ", x) 
  HTML(x,  Border = 5, innerBorder=1,align="center",row.names="FALSE")
 conv<-conv+1
 }
}

# 
MAN <- paste("<b>",q_dbmeteo$Manutenzione[i]     ,sep="")
NM  <- paste("<b>",q_dbmeteo$NoteManutenzione[i] ,sep="")
DL  <- paste("<b>",q_dbmeteo$DataLogger[i]       ,sep="")
NDL <- paste("<b>",q_dbmeteo$NoteDL[i]           ,sep="")
CON <- paste("<b>",q_dbmeteo$Connessione[i]      ,sep="")
NC  <- paste("<b>",q_dbmeteo$NoteConnessione[i]  ,sep="")
AL  <- paste("<b>",q_dbmeteo$Alimentazione[i]    ,sep="")
NAL <- paste("<b>",q_dbmeteo$NoteAlimentazione[i],sep="")
#
a<-c("Manutenzione:" ,MAN,"Note:", NM )
b<-c("DataLogger:"   ,DL ,"Note:", NDL)
c<-c("Connessione:"  ,CON,"Note:", NC )
d<-c("Alimentazione:",AL ,"Note:", NAL)
x<-data.frame(a,b,c,d)
x<-t(x)
x<-gsub("NA"," - ", x) 
x<-gsub("NULL"," - ", x) 
HTML(x,  Border = 5, innerBorder=1,align="left",row.names="FALSE")

HTMLhr()
HTMLhr()

#############################
# interroga DB su sensori 
#############################
q_dbmeteosensori <- NULL
 stringa_sensori<-paste("select * from A_Sensori where IDstazione=",q_dbmeteo$IDstazione[i]," ORDER BY NOMEtipologia",sep="")
q_dbmeteosensori <- try(dbGetQuery(conn, stringa_sensori),silent=TRUE)
if (inherits(q_dbmeteosensori,"try-error")) {
  print( "ERRORE nell'esecuzione query \n")
  dbDisconnect(conn)
  rm(conn)
  dbUnloadDriver(drv)
  quit(status=1)
}
# ciclo sui sensori
sens<-1
while (sens<=length(q_dbmeteosensori$IDsensore)) {
sensore<-""
## ricavo il nome della tipologia da A_Tipologia
q_dbmeteotip <- NULL
stringa_tip<-paste("select Info from A_Tipologia where A_Tipologia.Nome='",q_dbmeteosensori$NOMEtipologia[sens],"'",sep="")
if(is.na(q_dbmeteosensori$Aggregazione[sens])==T){
   aggreg<-""
}else{
  if(q_dbmeteosensori$Aggregazione[sens]=="V")aggreg<-"vettoriale"
  if(q_dbmeteosensori$Aggregazione[sens]=="P")aggreg<-"prevalente"
  if(q_dbmeteosensori$Aggregazione[sens]=="S")aggreg<-"scalare"
}

q_dbmeteotip <- try(dbGetQuery(conn, stringa_tip),silent=TRUE)
if (inherits(q_dbmeteotip,"try-error")) {
  print( "ERRORE nell'esecuzione query \n")
  dbDisconnect(conn)
  rm(conn)
  dbUnloadDriver(drv)
  quit(status=1)
}
sensore <- q_dbmeteotip 
HTML.title(paste(sensore,aggreg,sep=" "),  HR=3)

#GENERICHE SENSORI
IDS <-paste("<b>",q_dbmeteosensori$IDsensore[sens]  ,sep="")
DI  <-paste("<b>",q_dbmeteosensori$DataInizio[sens] ,sep="")
if(q_dbmeteosensori$DataFine[sens]=="0000-00-00" & is.na(q_dbmeteosensori$DataFine[sens])==F){
 DF  <-paste("<b>"," - "   ,sep="")
}else{
 DF  <-paste("<b>",q_dbmeteosensori$DataFine[sens]   ,sep="")
}
QUO <-paste("<b>",q_dbmeteosensori$Quota[sens]      ,sep="")
QE  <-paste("<b>",q_dbmeteosensori$QSedificio[sens] ,sep="")
QS  <-paste("<b>",q_dbmeteosensori$QSsupporto[sens] ,sep="")
ST  <-paste("<b>",q_dbmeteosensori$Storico[sens]    ,sep="")
#PU  <-paste("<b>",q_dbmeteosensori$Google[sens]     ,sep="")
NO  <-paste("<b>",q_dbmeteosensori$NoteQS[sens]     ,sep="")
#
a<-c("IDsensore:" ,IDS, "Data Inizio:"   ,DI, "Data Fine"      ,DF)
b<-c("Quota amsl:",QUO, "Quota Edificio:",QE, "Quota Supporto:",QS)
#c<-c("NOTE:"      ,NO , "Pubblicato:"    ,PU, ""               ,"")
c<-c("NOTE:"      ,NO ,"","","","")
x<-data.frame(a,b,c)
x<-t(x)
x<-gsub("NA"," - ", x) 
x<-gsub("NULL"," - ", x) 
if(q_dbmeteosensori$Storico[sens]=="Yes")HTML(x,  Border = 1, innerBorder=0,align="center",classcellinside="")
if(q_dbmeteosensori$Storico[sens]=="No" )HTML(x,  Border = 1, innerBorder=0,align="center")

 # interroga DB su strumenti installati 
 q_strumenti <- NULL
 stringa<-NULL
 stringa<-paste("select * from A_Sensori_specifiche where IDsensore=",q_dbmeteosensori$IDsensore[sens],sep="")
 q_strumenti <- try(dbGetQuery(conn, stringa),silent=TRUE)
 if (inherits(q_dbmeteosensori,"try-error")) {
   print( "ERRORE nell'esecuzione query \n")
   dbDisconnect(conn)
   rm(conn)
   dbUnloadDriver(drv)
   quit(status=1)
 }
 str<-1
 while (str<=length(q_strumenti$IDsensore)) {
  MA  <-paste("<b>",q_strumenti$Marca[str]              ,sep="")
  MO  <-paste("<b>",q_strumenti$Modello[str]            ,sep="")
  DIN <-paste("<b>",q_strumenti$DataIstallazione[str]   ,sep="")
  DFI <-paste("<b>",q_strumenti$DataDisistallazione[str],sep="")
  NOT <-paste("<b>",q_strumenti$Note[str]               ,sep="")
  a<-c("Marca:",MA,"Modello:",MO,"Data Inizio:",DIN,"Data Fine:",DFI,"NOTE:", NOT)
  x<-data.frame(a)
  x<-t(x)
  x<-gsub("NA"," - ", x) 
  x<-gsub("NULL"," - ", x) 
  HTML(x,  Border = 0, innerBorder=0, align="center",classcellinside="")
  str<-str+1
 }

sens<-sens+1
}


#############################
# carica mappe CONTESTO, DINTORNI, DETTAGLIO 
#############################
HTMLhr()
HTMLhr()
HTML.title("MAPPE", HR=3)
contesto <- paste("/applications/ortofoto_stazioni/50mila/100k_",q_dbmeteo$IDstazione[i],".png",sep="")
HTMLInsertGraph(contesto,
                Caption="CONTESTO", 
                GraphBorder=1, 
                Align="left")
              #  WidthHTML=200, 
                #HeightHTML=NULL)
dintorni <- paste("/applications/ortofoto_stazioni/10mila/10k_",q_dbmeteo$IDstazione[i],".png",sep="")
HTMLInsertGraph(dintorni,
                Caption="DINTORNI", 
                GraphBorder=1, 
                Align="center")
dettagli <- paste("/applications/ortofoto_stazioni/1mila/2k_",q_dbmeteo$IDstazione[i],".png",sep="")
HTMLInsertGraph(dettagli,
                Caption="DETTAGLIO", 
                GraphBorder=1, 
                Align="right")

#############################
# carica 3 foto significative recenti 
#############################
HTMLhr()
HTMLhr()
HTML.title("FOTO", HR=3)
foto1 <- paste("/applications/ortofoto_stazioni/foto/",q_dbmeteo$IDstazione[i],"/scheda/1.png",sep="")
HTMLInsertGraph(foto1,
               # Caption="DETTAGLI", 
                GraphBorder=1, 
                Align="left") 
foto2 <- paste("/applications/ortofoto_stazioni/foto/",q_dbmeteo$IDstazione[i],"/scheda/2.png",sep="")
HTMLInsertGraph(foto2,
               # Caption="DETTAGLI", 
                GraphBorder=1, 
                Align="center")
foto3 <- paste("/applications/ortofoto_stazioni/foto/",q_dbmeteo$IDstazione[i],"/scheda/3.png",sep="")
HTMLInsertGraph(foto3,
               # Caption="DETTAGLI", 
                GraphBorder=1, 
                Align="right")
#############################
# inserisce testo col codice del MODULO 
#############################
HTML.title("<br>MO.SI.014.Rev.00 del 19/02/2013",align="left",HR=3)

HTMLStop() 
  i<-i+1
}

# disconnessione
RetCode<-try(dbDisconnect(conn),silent=TRUE)
if (inherits(RetCode,"try-error")) {
  quit(status=1)
}
  rm(conn)
  dbUnloadDriver(drv)
quit()
