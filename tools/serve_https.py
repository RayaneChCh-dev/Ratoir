#!/usr/bin/env python3
"""Sert build/web/ en HTTPS sur le réseau local pour tester sur téléphone.

Godot Web exige un « contexte sécurisé » : en HTTP, seul http://localhost fonctionne.
Depuis un téléphone (http://192.168.x.x) le jeu refuse de démarrer, d'où ce serveur HTTPS
avec un certificat auto-signé (généré une fois dans build/certs/ via openssl).

Usage : python3 tools/serve_https.py [port]   (par défaut 8765)
Sur le téléphone : https://<IP-du-PC>:8765 puis « Paramètres avancés → Continuer ».
"""
import http.server
import os
import socket
import ssl
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB_DIR = os.path.join(ROOT, "build", "web")
CERT_DIR = os.path.join(ROOT, "build", "certs")
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8765


def lan_ip() -> str:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.connect(("10.255.255.255", 1))  # aucun paquet envoyé, sert juste à choisir l'interface
        return s.getsockname()[0]


def ensure_cert(ip: str) -> tuple[str, str]:
    os.makedirs(CERT_DIR, exist_ok=True)
    cert, key = os.path.join(CERT_DIR, "cert.pem"), os.path.join(CERT_DIR, "key.pem")
    if not os.path.exists(cert):
        subprocess.run(
            ["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-keyout", key,
             "-out", cert, "-days", "30", "-subj", f"/CN={ip}",
             "-addext", f"subjectAltName=IP:{ip},DNS:localhost"],
            check=True, capture_output=True)
    return cert, key


def main() -> None:
    if not os.path.exists(os.path.join(WEB_DIR, "index.html")):
        sys.exit("build/web/index.html introuvable : lance d'abord tools/export_web.sh")
    ip = lan_ip()
    cert, key = ensure_cert(ip)
    os.chdir(WEB_DIR)
    httpd = http.server.ThreadingHTTPServer(("0.0.0.0", PORT), http.server.SimpleHTTPRequestHandler)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(cert, key)
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
    print(f"Ouvre https://{ip}:{PORT} sur le téléphone (même Wi-Fi). Ctrl+C pour arrêter.")
    httpd.serve_forever()


if __name__ == "__main__":
    main()
