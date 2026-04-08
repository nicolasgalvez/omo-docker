#!/usr/bin/env python3
"""TCP proxy to forward Ollama requests from Docker containers to a LAN host.

Docker Desktop for Mac can't route to LAN IPs from inside containers.
This proxy runs on the Mac and forwards container traffic
(via host.docker.internal) to the Ollama server on the LAN.

Usage: ./ollama-proxy.py [OLLAMA_HOST] [LISTEN_PORT]
  OLLAMA_HOST  - remote Ollama address (default: 192.168.1.69:11434)
  LISTEN_PORT  - local port to listen on (default: 11434)
"""
import socket
import sys
import threading

BUFFER_SIZE = 65536


def forward(src, dst):
    try:
        while True:
            data = src.recv(BUFFER_SIZE)
            if not data:
                break
            dst.sendall(data)
    except (ConnectionResetError, BrokenPipeError, OSError):
        pass
    finally:
        src.close()
        dst.close()


def main():
    remote = sys.argv[1] if len(sys.argv) > 1 else "192.168.1.69:11434"
    listen_port = int(sys.argv[2]) if len(sys.argv) > 2 else 11434
    remote_host, remote_port = remote.rsplit(":", 1)
    remote_port = int(remote_port)

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("0.0.0.0", listen_port))
    server.listen(16)
    print(f"Forwarding :{listen_port} -> {remote_host}:{remote_port}")

    try:
        while True:
            client, addr = server.accept()
            upstream = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            try:
                upstream.connect((remote_host, remote_port))
            except OSError as e:
                print(f"Can't reach {remote_host}:{remote_port}: {e}")
                client.close()
                upstream.close()
                continue
            threading.Thread(target=forward, args=(client, upstream), daemon=True).start()
            threading.Thread(target=forward, args=(upstream, client), daemon=True).start()
    except KeyboardInterrupt:
        print("\nStopped.")
    finally:
        server.close()


if __name__ == "__main__":
    main()
