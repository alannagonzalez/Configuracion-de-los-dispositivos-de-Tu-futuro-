#!/bin/bash
# ==============================================================================
# SCRIPT DE CONFIGURACIÓN Y VERIFICACIÓN COMPLETA: SERVIDOR MAIL
# Dominio: hspcomercial.com.do
# Hostname: mail.hspcomercial.com.do
# Servicios: Postfix (SMTP - 25) + Dovecot (POP3 - 110 / IMAP - 143)
# ==============================================================================

# ------------------------------------------------------------------------------
# AUTO-ELEVACIÓN Y ASIGNACIÓN DE PERMISOS DE EJECUCIÓN
# ------------------------------------------------------------------------------
# Asignar permisos de ejecución automáticamente a sí mismo
chmod +x "$0" 2>/dev/null || true

# Verificar si el script se está ejecutando con sudo/root
if [ "$EUID" -ne 0 ]; then
  echo "[!] Este script requiere permisos de superusuario (sudo)."
  echo "[+] Reejecutando con sudo..."
  exec sudo "$0" "$@"
  exit $?
fi

set -e

echo "=============================================================================="
echo " 1. INSTALACIÓN DE PAQUETES (Postfix, Dovecot IMAP/POP3, Mailutils y Net-tools)"
echo "=============================================================================="
apt update
apt install -y postfix dovecot-imapd dovecot-pop3d mailutils net-tools telnet

echo ""
echo "=============================================================================="
echo " 2. CONFIGURACIÓN DE POSTFIX (/etc/postfix/main.cf)"
echo "=============================================================================="
postconf -e "myhostname = mail.hspcomercial.com.do"
postconf -e "mydomain = hspcomercial.com.do"
postconf -e "myorigin = /etc/mailname"
postconf -e "inet_interfaces = all"
postconf -e "mynetworks = 127.0.0.0/8, 192.168.0.0/16, 10.0.0.0/8"
postconf -e "home_mailbox = Maildir/"
postconf -e "mydestination = \$myhostname, hspcomercial.com.do, mail.hspcomercial.com.do, localhost.\$mydomain, localhost"
postconf -e "inet_protocols = ipv4"

echo ""
echo "=============================================================================="
echo " 3. CONFIGURACIÓN DE DOVECOT (Maildir y Autenticación)"
echo "=============================================================================="
grep -q "mail_location = maildir:~/Maildir" /etc/dovecot/conf.d/10-mail.conf || echo "mail_location = maildir:~/Maildir" | tee -a /etc/dovecot/conf.d/10-mail.conf
grep -q "disable_plaintext_auth = no" /etc/dovecot/conf.d/10-auth.conf || echo "disable_plaintext_auth = no" | tee -a /etc/dovecot/conf.d/10-auth.conf

echo ""
echo "=============================================================================="
echo " 4. REINICIO Y RECARGA DE SERVICIOS"
echo "=============================================================================="
service postfix restart
service dovecot restart

echo ""
echo "=============================================================================="
echo " 5. PRUEBA DE ENVÍO DE CORREO LOCAL"
echo "=============================================================================="
echo "Correo de prueba de la configuracion de MAIL" | mail -s "Prueba Servidor MAIL" admin@hspcomercial.com.do

echo ""
echo "=============================================================================="
echo " 6. VERIFICACIÓN DE ESTADO DE SERVICIOS (Postfix y Dovecot)"
echo "=============================================================================="
service postfix status | grep -E "Active:|running" || true
service dovecot status | grep -E "Active:|running" || true

echo ""
echo "=============================================================================="
echo " 7. VERIFICACIÓN DE PUERTOS Y PROTOCOLOS (25, 110, 143)"
echo "=============================================================================="
echo "[+] Puertos TCP en escucha con netstat:"
netstat -tuln | grep -E '25|110|143' || true

echo ""
echo "[+] Sockets activos con ss:"
ss -tulpn | grep -E '25|110|143' || true

echo ""
echo "=============================================================================="
echo " 8. VERIFICACIÓN DE CONFIGURACIÓN ACTIVA"
echo "=============================================================================="
echo "[+] Parámetros clave de Postfix cargados:"
postconf myhostname mydomain mynetworks home_mailbox mydestination

echo ""
echo "[+] Parámetros clave de Dovecot cargados:"
dovecot -n | grep -E "mail_location|disable_plaintext_auth" || true

echo ""
echo "=============================================================================="
echo " 9. VERIFICACIÓN DE BUZÓN Y LOGS DEL SISTEMA"
echo "=============================================================================="
echo "[+] Contenido de la bandeja Maildir/new:"
ls -la /home/admin/Maildir/new || true

echo ""
echo "[+] Últimos registros en /var/log/mail.log:"
tail -n 10 /var/log/mail.log 2>/dev/null || journalctl -u postfix -n 10 --no-pager || true

echo ""
echo "=============================================================================="
echo " ¡CONFIGURACIÓN Y VERIFICACIÓN COMPLETADAS EXITOSAMENTE!"
echo "=============================================================================="



