# Anagrafica IRIS_DEVEL
Codice per la creazione di un immagine di un container Docker che si occupa di eseguire una procedura per aggiornare quotidianamente l'anagrafica del database di IRIS di sviluppo/devel (DB POSTGRES: iris_devel).

Specificare le variabili d'ambiente:
- MYSQL_PWD
- PSQL_PWD
- DBMETEO_IP: 10.10.0.6

Il comando che esegue lo script che si occupa di aggiornare la tabella del DB di IRIS è già inserito nel Dockerfile!:
CMD ["./anagrafica_IRIS_DEVEL.sh"]

Volendo si potrebbe non scriverlo nel Dockerfile ma specificarlo all'avvio del container?
