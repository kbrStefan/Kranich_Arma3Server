import os
import re
import subprocess
import urllib.request

import keys

WORKSHOP = "steamapps/workshop/content/107410/"
USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.47 Safari/537.36"  # noqa: E501


def download(mods):
    def chunks(lst, n):
        for i in range(0, len(lst), n):
            yield lst[i:i + n]

    for mod_group in chunks(mods, 3):
        retries = 3
        while retries > 0:
            steamcmd = ["/steamcmd/steamcmd.sh"]
            steamcmd.extend(["+force_install_dir", "/arma3"])
            steamcmd.extend(["+login", os.environ["STEAM_USER"], os.environ["STEAM_PASSWORD"]])
            for id in mod_group:
                steamcmd.extend(["+workshop_download_item", "107410", id])
            steamcmd.extend(["+quit"])
            result = subprocess.call(steamcmd)
            if result == 0:
                break
            else:
                print(f"Download failed for mods {mod_group}, retries left: {retries-1}")
                retries -= 1
        if retries == 0:
            raise RuntimeError(f"Failed to download mods {mod_group} after 3 attempts.")


def preset(mod_file):
    if mod_file.startswith("http"):
        req = urllib.request.Request(
            mod_file,
            headers={"User-Agent": USER_AGENT},
        )
        remote = urllib.request.urlopen(req)
        with open("preset.html", "wb") as f:
            f.write(remote.read())
        mod_file = "preset.html"
    mods = []
    moddirs = []
    with open(mod_file) as f:
        html = f.read()
        regex = r"filedetails\/\?id=(\d+)\""
        matches = re.finditer(regex, html, re.MULTILINE)
        for _, match in enumerate(matches, start=1):
            mods.append(match.group(1))
            moddir = WORKSHOP + match.group(1)
            moddirs.append(moddir)
        download(mods)
        for moddir in moddirs:
            keys.copy(moddir)
    return moddirs
