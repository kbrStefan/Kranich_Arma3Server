import os
import re
import subprocess
import urllib.request
from time import sleep

import keys
import shutil
import glob

WORKSHOP = "steamapps/workshop/content/107410/"
#USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.47 Safari/537.36"  # noqa: E501
USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

STEAMCMDDIR = os.environ.get("STEAMCMDDIR")

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
                        print(f"Renaming {old} to {new}", flush=True)
                        os.rename(old, new)
                for name in dirs:
                    old = os.path.join(root, name)
                    new = os.path.join(root, name.lower())
                    if old != new:
                        print(f"Renaming {old} to {new}", flush=True)
                        os.rename(old, new)
    return path

def download(mods):
    def chunks(lst, n):
        for i in range(0, len(lst), n):
            yield lst[i:i + n]


    print(f"Number of mods entries: {len(mods)}", flush=True)
    existing_mods = [
        name for name in os.listdir(os.path.join("/arma3", WORKSHOP))
        if os.path.isdir(os.path.join("/arma3", WORKSHOP, name))
    ]
    print(f"Number of existing subfolders in /arma3/{WORKSHOP}: {len(existing_mods)}", flush=True)
    #sort the mods list to ensure consistent order
    mods.sort()
    if os.environ["SKIP_WORKSHOP_UPDATES"] in ["", "false"]:
        chunk_size = 10
    else:
        chunk_size = 1
    for mod_group in chunks(mods, chunk_size):
        retries = 3
        print(f"\033[34mDownloading mods {mod_group}\033[0m", flush=True)
        while retries > 0:
            steamcmd = [STEAMCMDDIR+"/steamcmd.sh"]
            steamcmd.extend(["+force_install_dir", "/arma3"])
            steamcmd.extend(["+login", os.environ["STEAM_USER"], os.environ["STEAM_PASSWORD"]])
            for id in mod_group:
                steamcmd.extend(["+workshop_download_item", "107410", id, "validate"])
            steamcmd.extend(["+quit"])
            result = subprocess.call(steamcmd)
            if result == 0:
                print(f"\033[32mSuccessfully downloaded mods {mod_group}\033[0m", flush=True)
                break
            else:
                print(f"\033[38;5;208mDownload failed for mods {mod_group}, retries left: {retries-1}\033[0m", flush=True)
                retries -= 1
                sleep(30)  # Wait before retrying
        if retries == 0:
            #raise RuntimeError(f"\033[31mFailed to download mods {mod_group} after 3 attempts.\033[0m")
            print(f"\033[31mFailed to download mods {mod_group}... scipping for now\033[0m", flush=True)


def get_client_side_mods(moddirs):
    client_mods = []
    for moddir in moddirs:
        pbos = glob.glob(os.path.join(moddir, "**", "*.pbo"), recursive=True)
        bikeys = glob.glob(os.path.join(moddir, "**", "*.bikey"), recursive=True)
        if pbos and not bikeys:
            client_mods.append(os.path.basename(moddir))
    print(f"Found {len(client_mods)} client-side mods: {client_mods}", flush=True)
    return client_mods

def get_missing_mods(mods, moddirs):
    missing_mods = [
        mod for mod in mods
        if not os.path.isdir(os.path.join("/arma3", WORKSHOP, mod))
        or not os.listdir(os.path.join("/arma3", WORKSHOP, mod))
    ]
    missing_mods.extend(keys.get_missing_keys(moddirs))
    print(f"Found {len(missing_mods)} missing mods: {missing_mods}", flush=True)
    return missing_mods

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
        print(f"Found {len(mods)} mods in preset file: {mod_file}", flush=True)
        if os.environ["SKIP_WORKSHOP_UPDATES"] in ["", "false"]:
            print(f"Downloading mods: {mods}", flush=True)
            download(mods)
        else:
            missing_mods = get_missing_mods(mods, moddirs)
            clientside_mods= get_client_side_mods(moddirs)
            if missing_mods:
                missing_mods = list(set(missing_mods))
                missing_mods = [mod for mod in missing_mods if mod not in clientside_mods]
                skipped_mods = [mod for mod in mods if mod not in missing_mods]
                print(f"\033[33m{len(missing_mods)} missing / broken mods: {missing_mods}\033[0m", flush=True)
                print(f"\033[92mFound {len(skipped_mods)}mods: {skipped_mods}\033[0m", flush=True)
                # Do not download mods as we let steam client do that
                #download(missing_mods)
        # After successful download, recursively lowercase all files and folders
        # and copy keys
        for moddir in moddirs:
            # do not lowercase mods as we mount it with ciopfs
            # new_mod_path = recursive_lowercase(moddir)
            # print(f"Recursively lowercased {moddir} to {new_mod_path}", flush=True)
            keys.copy(moddir)
        # Strip all clientside mods from the load list
        moddirs = [moddir for moddir in moddirs if os.path.basename(moddir) not in clientside_mods]
    print(f"Returning {len(moddirs)} mods", flush=True)
    return moddirs
