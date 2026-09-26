#!/usr/bin/env python3
"""Prépare un modèle .glb (Meshy, Tripo…) pour le jeu, sans Blender.

- Réduit les textures (1024 px par défaut) et retire les cartes PBR inutiles
  pour notre rendu mobile (reflets métalliques, relief, occlusion) ainsi que les tangentes.
- Fusionne dans un seul fichier les animations exportées séparément
  (ex. Meshy donne un .glb par animation, chacun avec le modèle et ses textures).
- Renomme les animations et supprime les doublons « .001 » (poses figées d'une image).

Exemples :
  python3 tools/optimize_glb.py walking.glb -o assets/models/characters/chef.glb \\
      --anim-from running.glb --rename Walking=walk --rename Running=run

  python3 tools/optimize_glb.py stove_meshy.glb -o assets/models/kitchen/stove.glb --texture-size 512

Prérequis : Python 3 + Pillow (`pip install pillow`).
"""
import argparse
import io
import json
import re
import struct
import sys

from PIL import Image

GLB_MAGIC = b"glTF"
CHUNK_JSON = b"JSON"
CHUNK_BIN = b"BIN\x00"
PBR_TEXTURE_KEYS = ("normalTexture", "occlusionTexture")


class Glb:
    def __init__(self, path: str):
        data = open(path, "rb").read()
        if data[:4] != GLB_MAGIC:
            sys.exit(f"{path} n'est pas un fichier .glb")
        offset, self.json, self.bin = 12, None, b""
        while offset < len(data):
            length, kind = struct.unpack("<I4s", data[offset:offset + 8])
            chunk = data[offset + 8:offset + 8 + length]
            if kind == CHUNK_JSON:
                self.json = json.loads(chunk)
            elif kind == CHUNK_BIN:
                self.bin = chunk
            offset += 8 + length
        self.path = path

    def view_bytes(self, index: int) -> bytes:
        view = self.json["bufferViews"][index]
        start = view.get("byteOffset", 0)
        return self.bin[start:start + view["byteLength"]]


class Writer:
    """Reconstruit un buffer binaire ne contenant que les données réellement utilisées."""

    def __init__(self):
        self.bin = bytearray()
        self.views: list[dict] = []
        self.accessors: list[dict] = []
        self._view_cache: dict[tuple[int, int], int] = {}

    def add_bytes(self, data: bytes, **view_fields) -> int:
        while len(self.bin) % 4:
            self.bin.append(0)
        self.views.append({"buffer": 0, "byteOffset": len(self.bin), "byteLength": len(data), **view_fields})
        self.bin.extend(data)
        return len(self.views) - 1

    def copy_view(self, src: Glb, index: int) -> int:
        key = (id(src), index)
        if key not in self._view_cache:
            view = src.json["bufferViews"][index]
            extra = {k: v for k, v in view.items() if k in ("byteStride", "target")}
            self._view_cache[key] = self.add_bytes(src.view_bytes(index), **extra)
        return self._view_cache[key]

    def copy_accessor(self, src: Glb, index: int) -> int:
        accessor = dict(src.json["accessors"][index])
        if "sparse" in accessor:
            sys.exit("Accessors « sparse » non gérés par ce script")
        if "bufferView" in accessor:
            accessor["bufferView"] = self.copy_view(src, accessor["bufferView"])
        self.accessors.append(accessor)
        return len(self.accessors) - 1


def resize_image(data: bytes, max_size: int) -> tuple[bytes, str, str]:
    image = Image.open(io.BytesIO(data))
    before = f"{image.width}×{image.height}"
    if max(image.size) > max_size:
        image.thumbnail((max_size, max_size), Image.LANCZOS)
    out = io.BytesIO()
    has_alpha = image.mode in ("RGBA", "LA") or "transparency" in image.info
    if has_alpha:
        image.save(out, "PNG", optimize=True)
        mime = "image/png"
    else:
        image.convert("RGB").save(out, "JPEG", quality=85, optimize=True)
        mime = "image/jpeg"
    return out.getvalue(), mime, f"{before} → {image.width}×{image.height}"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("base", help=".glb de départ (modèle + squelette + animation éventuelle)")
    parser.add_argument("-o", "--output", required=True, help=".glb optimisé à écrire")
    parser.add_argument("--anim-from", action="append", default=[], metavar="GLB",
                        help="Autre .glb (même squelette) dont on importe les animations. Répétable.")
    parser.add_argument("--rename", action="append", default=[], metavar="ANCIEN=NOUVEAU",
                        help="Renomme une animation. Répétable.")
    parser.add_argument("--drop-anim", default=r"\.\d{3}$", metavar="REGEX",
                        help="Supprime les animations dont le nom correspond (défaut : doublons « .001 »)")
    parser.add_argument("--texture-size", type=int, default=1024, help="Taille max des textures (défaut 1024)")
    parser.add_argument("--keep-pbr", action="store_true",
                        help="Garde les cartes métal/rugosité, relief et occlusion (déconseillé sur mobile)")
    args = parser.parse_args()

    base = Glb(args.base)
    src_json = base.json
    triangles = sum(src_json["accessors"][p["indices"]]["count"] // 3
                    for m in src_json.get("meshes", []) for p in m["primitives"] if "indices" in p)
    out = {k: v for k, v in src_json.items()
           if k not in ("accessors", "bufferViews", "buffers", "images", "textures", "animations")}
    writer = Writer()
    renames = dict(item.split("=", 1) for item in args.rename)
    drop = re.compile(args.drop_anim) if args.drop_anim else None

    # Maillages et squelettes.
    for mesh in out.get("meshes", []):
        for prim in mesh["primitives"]:
            if not args.keep_pbr:
                prim["attributes"].pop("TANGENT", None)
            prim["attributes"] = {k: writer.copy_accessor(base, v) for k, v in prim["attributes"].items()}
            if "indices" in prim:
                prim["indices"] = writer.copy_accessor(base, prim["indices"])
            for target in prim.get("targets", []):
                for key in target:
                    target[key] = writer.copy_accessor(base, target[key])
    for skin in out.get("skins", []):
        if "inverseBindMatrices" in skin:
            skin["inverseBindMatrices"] = writer.copy_accessor(base, skin["inverseBindMatrices"])

    # Animations (celles du fichier de base + celles des autres fichiers, nœuds associés par nom).
    node_by_name = {n.get("name"): i for i, n in enumerate(out.get("nodes", []))}
    animations, names = [], []
    for src in [base] + [Glb(p) for p in args.anim_from]:
        for anim in src.json.get("animations", []):
            name = anim.get("name", f"anim_{len(animations)}")
            if drop and drop.search(name):
                continue
            name = renames.get(name, name)
            if name in names:
                sys.exit(f"Animation « {name} » en double : utiliser --rename")
            samplers = [{**s, "input": writer.copy_accessor(src, s["input"]),
                         "output": writer.copy_accessor(src, s["output"])} for s in anim["samplers"]]
            channels = []
            for ch in anim["channels"]:
                node_name = src.json["nodes"][ch["target"]["node"]].get("name")
                if node_name not in node_by_name:
                    sys.exit(f"{src.path} : l'os « {node_name} » n'existe pas dans {base.path}")
                channels.append({**ch, "target": {**ch["target"], "node": node_by_name[node_name]}})
            animations.append({"name": name, "samplers": samplers, "channels": channels})
            names.append(name)
    if animations:
        out["animations"] = animations

    # Matériaux : on ne garde que la couleur (et l'émission) sauf --keep-pbr.
    for material in out.get("materials", []):
        pbr = material.setdefault("pbrMetallicRoughness", {})
        if not args.keep_pbr:
            pbr.pop("metallicRoughnessTexture", None)
            pbr["metallicFactor"] = 0.0
            pbr["roughnessFactor"] = 1.0
            for key in PBR_TEXTURE_KEYS:
                material.pop(key, None)

    # Textures réellement utilisées, réencodées à la bonne taille.
    used_textures: dict[int, int] = {}
    textures, images = [], []

    def remap(ref: dict) -> None:
        old = ref["index"]
        if old not in used_textures:
            tex = dict(src_json["textures"][old])
            img = src_json["images"][tex["source"]]
            data, mime, info = resize_image(base.view_bytes(img["bufferView"]), args.texture_size)
            print(f"  texture {len(images)} : {info} ({len(data) // 1024} Kio)")
            images.append({"bufferView": writer.add_bytes(data), "mimeType": mime})
            tex["source"] = len(images) - 1
            textures.append(tex)
            used_textures[old] = len(textures) - 1
        ref["index"] = used_textures[old]

    for material in out.get("materials", []):
        for holder in (material, material.get("pbrMetallicRoughness", {})):
            for key, value in holder.items():
                if key.endswith("Texture") and isinstance(value, dict) and "index" in value:
                    remap(value)
    if textures:
        out["textures"], out["images"] = textures, images

    out["accessors"], out["bufferViews"] = writer.accessors, writer.views
    out["buffers"] = [{"byteLength": len(writer.bin)}]
    out.setdefault("asset", {})["generator"] = "Ratoir tools/optimize_glb.py"

    json_bytes = json.dumps(out, separators=(",", ":")).encode()
    json_bytes += b" " * (-len(json_bytes) % 4)
    bin_bytes = bytes(writer.bin) + b"\x00" * (-len(writer.bin) % 4)
    total = 12 + 8 + len(json_bytes) + 8 + len(bin_bytes)
    with open(args.output, "wb") as f:
        f.write(struct.pack("<4sII", GLB_MAGIC, 2, total))
        f.write(struct.pack("<I4s", len(json_bytes), CHUNK_JSON) + json_bytes)
        f.write(struct.pack("<I4s", len(bin_bytes), CHUNK_BIN) + bin_bytes)

    print(f"OK : {args.output} ({total / 1e6:.1f} Mo), {triangles} triangles, animations : {names or 'aucune'}")


if __name__ == "__main__":
    main()
