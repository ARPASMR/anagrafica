# Aggiornamento anagrafica IRIS
Codice per la creazione di un immagine di un container Docker che si occupa di eseguire una procedura per aggiornare quotidianamente l'anagrafica del database di IRIS (DB POSTGRES: iris_base).

Specificare le variabili d'ambiente:
- MYSQL_PWD  (password del DB METEO)
- PSQL_PWD   (password del DB IRIS)
- PSQL_DB    (facoltativo, nome del DB, default iris_base)


NB. L'IP del DB METEO è specificato all'interno dello script anagrafica_IRIS_new.R (10.10.0.6). Magari si potrebbe esportare come variabile d'ambiente da passare all'avvio del container? Es. DBMETEO_IP

Il comando che esegue lo script che si occupa di aggiornare la tabella del DB di IRIS è già inserito nel Dockerfile:
CMD ["./anagrafica_IRIS.sh"]
