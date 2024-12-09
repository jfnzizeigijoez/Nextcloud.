#!/bin/bash
# Configuration
ftp_server="192.168.20.60"
ftp_user="ftpusers"
ftp_password="sio"
ftp_remote_dir="/home/user/archive"  # Remplacez par le répertoire distant approprié

# Chemin du fichier log
log_path="/home/sisr-6/tp/toip/fichier.csv"

# Chemin de sauvegarde local
local_backup_dir="/home/sisr-6/archive"
log_filename="sio2-$(date +%d-%m-%Y_%H:%M:%S)"

# Vérification si le dossier de sauvegarde local existe, sinon le créer
mkdir -p "$local_backup_dir"

# Sauvegarde locale du fichier log
if cp "$log_path" "$local_backup_dir/$log_filename.log"; then
    echo "Sauvegarde locale réussie : $local_backup_dir/$log_filename.log"
else
    echo "Échec de la sauvegarde locale."
    exit 1
fi

# Compression du fichier log avec tar et gzip
if tar -czf "$local_backup_dir/$log_filename.tar.gz" -C "$local_backup_dir" "$log_filename.log"; then
    echo "Compression réussie : $local_backup_dir/$log_filename.tar.gz"
else
    echo "Échec de la compression."
    exit 1
fi

# Transfert vers le serveur FTP
ftp -inv $ftp_server << EOF > /tmp/ftp_transfer.log 2>&1
user $ftp_user $ftp_password
cd $ftp_remote_dir
put "$local_backup_dir/$log_filename.tar.gz"
bye
EOF

# Vérifier si le transfert a réussi
if grep -q "Not connected" /tmp/ftp_transfer.log || grep -q "Connection refused" /tmp/ftp_transfer.log; then
  echo "Échec du transfert FTP. Voir les logs : /tmp/ftp_transfer.log"
  exit 1
else
  echo "Transfert FTP réussi : $log_filename.tar.gz"
fi

