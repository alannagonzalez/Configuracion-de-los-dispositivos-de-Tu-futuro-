# ==========================================
# 1. CONFIGURACIÓN DE RED E INTERFAZ ETH1
# ==========================================
sudo ip addr add 192.168.4.10/25 dev eth1 2>/dev/null || true
sudo ip link set eth1 up

sudo bash -c 'cat > /etc/resolv.conf <<EOF
nameserver 127.0.0.1
nameserver 8.8.8.8
EOF'

# ==========================================
# 2. CONFIGURACIÓN DEL SERVIDOR DNS (NAMED)
# ==========================================
sudo bash -c 'cat > /etc/bind/named.conf.local <<EOF
zone "hspcomercial.com.do" {
    type master;
    file "/etc/bind/db.hspcomercial.com.do";
};
EOF'

sudo bash -c 'cat > /etc/bind/db.hspcomercial.com.do <<EOF
\$TTL    604800
@       IN      SOA     ns1.hspcomercial.com.do. admin.hspcomercial.com.do. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL

@       IN      NS      ns1.hspcomercial.com.do.
ns1     IN      A       192.168.4.10
@       IN      A       192.168.4.10
www     IN      A       192.168.4.10
EOF'

sudo service named restart

# ==========================================
# 3. CONFIGURACIÓN DEL SERVIDOR WEB DNS-HCP (NGINX)
# ==========================================
echo "<h1>Bienvenido a HSP Comercial - Sede Santiago</h1>" | sudo tee /var/www/html/index.html
sudo service nginx restart

# ==========================================
# 4. CONFIGURACIÓN DEL SERVIDOR DHCP
# ==========================================
sudo bash -c 'cat > /etc/dhcp/dhcpd.conf <<EOF
default-lease-time 600;
max-lease-time 7200;
authoritative;

# VLAN 30 - Ventas (192.168.5.0/25)
subnet 192.168.5.0 netmask 255.255.255.128 {
  range 192.168.5.10 192.168.5.120;
  option routers 192.168.5.1;
  option domain-name-servers 192.168.4.10;
  option domain-name "hspcomercial.com.do";
}

# VLAN 35 - Administracion (192.168.5.128/25)
subnet 192.168.5.128 netmask 255.255.255.128 {
  range 192.168.5.138 192.168.5.250;
  option routers 192.168.5.129;
  option domain-name-servers 192.168.4.10;
  option domain-name "hspcomercial.com.do";
}
EOF'

sudo bash -c 'cat > /etc/default/isc-dhcp-server <<EOF
INTERFACESv4="eth1"
INTERFACESv6=""
EOF'

sudo service isc-dhcp-server restart

# ==========================================
# 5. COMANDOS DE VERIFICACIÓN AUTOMÁTICOS
# ==========================================
echo -e "\n=========================================="
echo "          RESULTADOS DE VERIFICACIÓN      "
echo "=========================================="

echo -e "\n--- [1] ESTADO DE LOS SERVICIOS ---"
sudo service named status | grep -E "Active|running"
sudo service nginx status | grep -E "Active|running"
sudo service isc-dhcp-server status | grep -E "Active|running"

echo -e "\n--- [2] PRUEBA DNS LOCAL ---"
nslookup www.hspcomercial.com.do 127.0.0.1

echo -e "\n--- [3] PRUEBA WEB POR DOMINIO ---"
curl -s http://www.hspcomercial.com.do

echo -e "\n--- [4] PRUEBA WEB POR IP ---"
curl -s http://192.168.4.10

echo -e "\n=========================================="

