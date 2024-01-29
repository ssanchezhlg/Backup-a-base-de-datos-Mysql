#!/bin/bash

# Datos del MYSQl
HOST="10.10.10.110"
PORT="3306"
USER="root"
PASSWORD="password"

# Definir bases de datos directamente en el script
DATABASES=('radiusmail' 'apps' 'blogs' 'catalogo')

# Our Base backup directory
BASEBACKUP="/srv/webinfomed"

# Número de días a mantener
dias_a_mantener=3

LOGDIR="/var/log/BackupSQL/$FECHA_ACTUAL"
ARCHIVO_LOG="$LOGDIR/Backup_$(date '+%Y-%m-%d_%I.%M.%S_%p').log" 
hostname="$(hostname -f)"


# Datos para el envío de correo
SUBJECT="BACKUP MYSQL - $hostname - COMPLETE"
EMAIL="root@hlg.sld.cu"
EMAILMESSAGE="/tmp/emailmessage.txt"

 
# Set a value that we can use for a datestamp
FECHA_ACTUAL=$(date +"%Y-%m-%d")

# Calcular la fecha límite
fecha_limite=$(date -d "$FECHA_ACTUAL - $dias_a_mantener days" +%Y-%m-%d)

# This is where we throw our backups.
BACKUP_DIR="$BASEBACKUP/$FECHA_ACTUAL"

# Directorio donde se guardara la base de datos
[ ! -d ${BACKUP_DIR} ] && mkdir -p ${BACKUP_DIR} 2>/dev/null

# Crear el directorio de logs si no existe
mkdir -p $LOGDIR

# Initialize log file.
echo "----"                                                                                              >> $EMAILMESSAGE 
echo " "                                                                                                 >> $EMAILMESSAGE
echo "* Iniciando Backups: ${FECHA_ACTUAL}."                                                             >> $EMAILMESSAGE
echo "* Backup Directorio: ${BACKUP_DIR}."                                                               >> $EMAILMESSAGE
echo "* Bases de Datos a Salvar: ${DATABASES[*]}"                                                        >> $EMAILMESSAGE

echo -e "\n* Tamaño     Fichero"                                                                         >> $EMAILMESSAGE
echo "----"                                                                                              >> $EMAILMESSAGE

for DATABASE in "${DATABASES[@]}"
do
  # Aquí puedes realizar tus operaciones de backup
  mysqldump --host=$HOST --port=$PORT --user=$USER --password=$PASSWORD --opt $DATABASE | gzip -c -9 > $BACKUP_DIR/$DATABASE-$FECHA_ACTUAL.sql.gz
  SIZE_AFTER=$(du -h --apparent-size $BACKUP_DIR/$DATABASE-$FECHA_ACTUAL.sql.gz | awk '{print $1}')
  printf "%-10s\t%s-%s.sql.gz\n" "$SIZE_AFTER" "$DATABASE" "$FECHA_ACTUAL"                                >> $EMAILMESSAGE
done 

echo "----"                                                                                               >> $EMAILMESSAGE  
echo "==> Backup completado con éxito."                                                                   >> $EMAILMESSAGE 
echo "=========================================================="                                         >> $EMAILMESSAGE
echo " "                                                                                                  >> $EMAILMESSAGE
echo " "                                                                                                  >> $EMAILMESSAGE
echo "* Eliminar backups con mas de $dias_a_mantener Días"                                                >> $EMAILMESSAGE



# Eliminar directorios viejos
# Cambiar al directorio principal
cd "$BASEBACKUP" || exit

# Obtener la lista de directorios ordenados por nombre
directorios=($(ls -1 | sort))                                                           

# Iterar sobre los directorios y eliminar los que no están en los últimos N días
for directorio in "${directorios[@]}"; do
    if [[ "$directorio" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        if [[ "$directorio" < "$fecha_limite" ]]; then
		    #rm -r "$directorio"
            echo "Directorio eliminado: $directorio"                                                       >> $EMAILMESSAGE                              
        fi
    fi
done

# 
echo " "                                                                                                  >> $EMAILMESSAGE
echo "----"                                                                                               >> $EMAILMESSAGE  
echo "==> Todas las tareas se han completado con éxito."                                                  >> $EMAILMESSAGE 
echo " "                                                                                                  >> $EMAILMESSAGE
echo " "                                                                                                  >> $EMAILMESSAGE
echo "----"                                                                                               >> $EMAILMESSAGE  
echo "Asistente virtual - Nodo Infomed Holguin"                                                           >> $EMAILMESSAGE
echo "Esta dirección electrónica está protegida contra spam bots"                                         >> $EMAILMESSAGE



# Funcion para enviar el Correo
#mail -s "$SUBJECT" "$EMAIL" < $EMAILMESSAGE



# Añadir el contenido del archivo de mensaje de correo al archivo de registro
cat "$EMAILMESSAGE" >> "$ARCHIVO_LOG"
#rm -f $EMAILMESSAGE
exit 0 