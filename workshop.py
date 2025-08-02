import os
import re
import subprocess
import urllib.request

import keys

WORKSHOP = "steamapps/workshop/content/107410/"
#USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.47 Safari/537.36"  # noqa: E501
USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

STEAMCMDDIR = os.environ.get("STEAMCMDDIR")

def download(mods):
    def chunks(lst, n):
        for i in range(0, len(lst), n):
            yield lst[i:i + n]

    def recursive_lowercase(path):
        # Only process 'addons' and 'keys' subfolders
        for subfolder in ['addons', 'keys']:
            target_dir = os.path.join(path, subfolder)
            if os.path.isdir(target_dir):
                for root, dirs, files in os.walk(target_dir, topdown=False):
                    for name in files:
                        old = os.path.join(root, name)
                        new = os.path.join(root, name.lower())
                        if old != new:
                            os.rename(old, new)
                    for name in dirs:
                        old = os.path.join(root, name)
                        new = os.path.join(root, name.lower())
                        if old != new:
                            os.rename(old, new)
        return path

    print(f"Number of mods entries: {len(mods)}", flush=True)
    existing_mods = [
        name for name in os.listdir(os.path.join("/arma3", WORKSHOP))
        if os.path.isdir(os.path.join("/arma3", WORKSHOP, name))
    ]
    print(f"Number of existing subfolders in /arma3/{WORKSHOP}: {len(existing_mods)}", flush=True)
    #sort the mods list to ensure consistent order
    mods.sort()
    for mod_group in chunks(mods, len(mods)):
        retries = 3
        print(f"\033[34mDownloading mods {mod_group}\033[0m", flush=True)
        while retries > 0:
            steamcmd = [STEAMCMDDIR+"/steamcmd.sh"]
            steamcmd.extend(["+force_install_dir", "/arma3"])
            steamcmd.extend(["+login", os.environ["STEAM_USER"], os.environ["STEAM_PASSWORD"]])
            for id in mod_group:
                steamcmd.extend(["+workshop_download_item", "107410", id])
            steamcmd.extend(["+quit"])
            result = subprocess.call(steamcmd)
            if result == 0:
                # After successful download, recursively lowercase all files and folders
                for id in mod_group:
                    mod_path = os.path.join("/arma3", WORKSHOP, id)
                    if os.path.exists(mod_path):
                        new_mod_path = recursive_lowercase(mod_path)
                        print(f"Recursively lowercased {mod_path} to {new_mod_path}", flush=True)
                print(f"\033[32mSuccessfully downloaded mods {mod_group}\033[0m", flush=True)
                break
            else:
                print(f"\033[38;5;208mDownload failed for mods {mod_group}, retries left: {retries-1}\033[0m", flush=True)
                retries -= 1
        if retries == 0:
            #raise RuntimeError(f"\033[31mFailed to download mods {mod_group} after 3 attempts.\033[0m")
            print(f"\033[31mFailed to download mods {mod_group}... scipping for now\033[0m", flush=True)


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
