#!/bin/bash
# ==============================================================================
# Script de Despliegue y Verificación de FTP (vsftpd) y FreeRADIUS
# Servidor: FTP-RADIUS | Módulo 6 (Santiago)
# ==============================================================================

set -e

# Colores para salida interactiva
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  Iniciando Instalación y Configuración FTP/RADIUS   ${NC}"
echo -e "${BLUE}======================================================${NC}"

# 1. Actualizar repositorios e instalar paquetes
echo -e "\n${YELLOW}[1/4] Instalando paquetes (vsftpd, ftp, freeradius, freeradius-utils)...${NC}"
apt update -y
apt install -y vsftpd ftp freeradius freeradius-utils

# 2. Configurar Servidor FTP
echo -e "\n${YELLOW}[2/4] Configurando Servidor FTP (vsftpd)...${NC}"
service vsftpd start || systemctl start vsftpd
service vsftpd status || systemctl status vsftpd

# Crear usuario ftpuser si no existe
if ! id "ftpuser" &>/dev/null; then
    echo -e "${BLUE}Creando usuario 'ftpuser'...${NC}"
    useradd -m -s /bin/bash ftpuser
    echo "ftpuser:1234" | chpasswd
    echo -e "${GREEN}Usuario 'ftpuser' creado con clave '1234'.${NC}"
else
    echo -e "${GREEN}El usuario 'ftpuser' ya existe.${NC}"
fi

# 3. Configurar FreeRADIUS
echo -e "\n${YELLOW}[3/4] Configurando FreeRADIUS...${NC}"
# Agregar usuario1 si no está presente en el archivo
USERS_FILE="/etc/freeradius/3.0/users"
if [ -f "$USERS_FILE" ]; then
    if ! grep -q 'usuario1' "$USERS_FILE"; then
        echo 'usuario1 Cleartext-Password := "clave123"' >> "$USERS_FILE"
        echo -e "${GREEN}Usuario 'usuario1' añadido a FreeRADIUS.${NC}"
    fi
fi

service freeradius restart || systemctl restart freeradius

# 4. Pruebas de Verificación
echo -e "\n${YELLOW}[4/4] Ejecutando Pruebas de Verificación...${NC}"

# A. Verificación de puertos
echo -e "\n${BLUE}--> Puertos en escucha (21=FTP, 1812/1813=RADIUS):${NC}"
ss -tuln | grep -E '21|1812|1813' || netstat -tuln | grep -E '21|1812|1813'

# B. Prueba de autenticación RADIUS
echo -e "\n${BLUE}--> Probando autenticación FreeRADIUS con 'radtest':${NC}"
RADIUS_TEST=$(radtest usuario1 clave123 127.0.0.1 0 testing123)

echo "$RADIUS_TEST"

if echo "$RADIUS_TEST" | grep -q "Received Access-Accept"; then
    echo -e "\n${GREEN}[ÉXITO] Autenticación RADIUS exitosa (Access-Accept recibido).${NC}"
else
    echo -e "\n${RED}[ERROR] Falló la prueba de RADIUS.${NC}"
fi

echo -e "\n${BLUE}======================================================${NC}"
echo -e "${GREEN}      ¡Configuración completada exitosamente!         ${NC}"
echo -e "${BLUE}======================================================${NC}"


