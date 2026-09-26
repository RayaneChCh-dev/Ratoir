#!/usr/bin/env python3
"""Voix du critique pour la démo. Le jeu choisit la phrase.

    python3 server/speak.py

Lit server/.env : GRADIUM_API_KEY, GRADIUM_VOICE_ID.
Écoute http://127.0.0.1:8787/speak
"""

import base64
import json
import os
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HOST = "127.0.0.1"
PORT = 8787
GRADIUM_URL = "https://api.gradium.ai/api/post/speech/tts"
DEFAULT_VOICE_ID = "dh0EzP6jCroK6prq"
MAX_BODY = 8_000


def load_env(path: str) -> None:
	if not os.path.isfile(path):
		return
	with open(path, encoding="utf-8") as handle:
		for line in handle:
			line = line.strip()
			if not line or line.startswith("#") or "=" not in line:
				continue
			key, value = line.split("=", 1)
			os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def speak_wav(text: str, api_key: str, voice_id: str) -> bytes:
	payload = json.dumps({
		"text": text,
		"voice_id": voice_id,
		"output_format": "wav",
		"only_audio": True,
		# Négatif = plus rapide (−4 à 0). −3.5 est proche du maximum.
		"json_config": json.dumps({"padding_bonus": -3.5}),
	}).encode("utf-8")
	request = urllib.request.Request(
		GRADIUM_URL,
		data=payload,
		headers={"Content-Type": "application/json", "x-api-key": api_key},
		method="POST",
	)
	with urllib.request.urlopen(request, timeout=6) as response:
		wav = response.read()
	if len(wav) < 44 or not wav.startswith(b"RIFF"):
		raise ValueError("gradium did not return a wav")
	return wav


class SpeakHandler(BaseHTTPRequestHandler):
	def do_OPTIONS(self) -> None:
		self.send_response(204)
		self.send_header("Access-Control-Allow-Origin", "*")
		self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		self.send_header("Access-Control-Allow-Headers", "Content-Type")
		self.end_headers()

	def do_GET(self) -> None:
		if self.path.split("?", 1)[0] not in ("/", "/speak"):
			self._json(404, {"error": "not_found"})
			return
		self._json(200, {"ok": True})

	def do_POST(self) -> None:
		if self.path.split("?", 1)[0] != "/speak":
			self._json(404, {"error": "not_found"})
			return
		length = int(self.headers.get("Content-Length", "0"))
		if length <= 0 or length > MAX_BODY:
			self._json(400, {"error": "bad_body"})
			return
		try:
			payload = json.loads(self.rfile.read(length).decode("utf-8"))
		except (UnicodeError, json.JSONDecodeError):
			self._json(400, {"error": "bad_json"})
			return
		text = str(payload.get("text", "")).strip()
		if not text or len(text) > 180:
			self._json(400, {"error": "bad_text"})
			return
		api_key = os.environ.get("GRADIUM_API_KEY", "")
		voice_id = os.environ.get("GRADIUM_VOICE_ID", "") or DEFAULT_VOICE_ID
		if not api_key:
			self._json(503, {"error": "missing_keys"})
			return
		try:
			wav = speak_wav(text, api_key, voice_id)
		except Exception as exc:
			print("speak failed: %s: %s" % (type(exc).__name__, exc))
			self._json(502, {"error": "speak_failed"})
			return
		print("speak ok: %s" % text)
		self._json(200, {"text": text, "audio_base64": base64.b64encode(wav).decode("ascii")})

	def _json(self, code: int, payload: dict) -> None:
		raw = json.dumps(payload).encode("utf-8")
		self.send_response(code)
		self.send_header("Content-Type", "application/json; charset=utf-8")
		self.send_header("Content-Length", str(len(raw)))
		self.send_header("Access-Control-Allow-Origin", "*")
		self.end_headers()
		self.wfile.write(raw)

	def log_message(self, fmt: str, *args) -> None:
		print("%s - %s" % (self.address_string(), fmt % args))


def main() -> None:
	load_env(os.path.join(os.path.dirname(__file__), ".env"))
	server = ThreadingHTTPServer((HOST, PORT), SpeakHandler)
	print("critic proxy on http://%s:%s/speak" % (HOST, PORT), flush=True)
	server.serve_forever()


if __name__ == "__main__":
	main()
