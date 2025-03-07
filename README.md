```
 ██████╗ ██╗  ██╗██████╗ ███████╗██████╗ ███████╗
██╔════╝ ██║  ██║██╔══██╗██╔════╝██╔══██╗██╔════╝
███████╗ ███████║██████╔╝███████╗██║  ██║███████╗
██╔═══██╗╚════██║██╔══██╗╚════██║██║  ██║╚════██║
╚██████╔╝     ██║██████╔╝███████║██████╔╝███████║
 ╚═════╝      ╚═╝╚═════╝ ╚══════╝╚═════╝ ╚══════╝
```

How to guide on installing and starting a 64-bit Counter-Strike: Source or Half-Life Deathmatch: Source, Half-Life 2: Deathmatch, Day of Defeat: Source dedicated server

# Prerequisites

Host already has `steam` user created and `steamcmd` installed. Guide: [SteamCMD#Linux](https://developer.valvesoftware.com/wiki/SteamCMD#Linux)

Using user called `server` for deploying and running the server.

> [!NOTE]
> If using different user please update steamcmd-scripts: 
```sh
for steamcmdscript in css dods hl2dm hldm tf2; do
    sed -i "s#/home/server/#/home/${USER}/#g" steamcmd-scripts/update_$steamcmdscript\_ds.txt
done
```

Confirm `libncurses5 libncurses5:i386 lib32z1` dependencies were installed

# Quick-start

```sh
git clone https://github.com/noillt/64bit-source-dedicated-server.git && cd 64bit-source-dedicated-server
./install-server.sh css # or dods,hldm,hl2dm
```

# Manually

```sh
git clone https://github.com/noillt/64bit-source-dedicated-server.git
cd 64bit-source-dedicated-server
```

## Prepare dedicated server files

> [!NOTE]
> This also applies to HL:DM, DOD:S, HL2:DM! Just replace `css` with `{hldm,dods,hl2dm}` in this guide and scripts
```sh
export servertoinstall="changeme" # to hldm,dods,hl2dm
sed -i "s/update_css_/update_$servertoinstall\_/g" README.md
sed -i "s/css-serverfiles/$servertoinstall-serverfiles/g" README.md
sed -i "s/css-serverfiles/$servertoinstall-serverfiles/g" run.sh
```

### Install Counter-Srike: Source & TF2 Dedicated servers

Currently Half-Life Deathmatch: Source, Day of Defeat: Source and Counter-Strike: Source, Half-Life 2: Deathmatch dedicated server files are missing a steam api library and server run binaries for 64-bit. Because of that we will have to do these additional steps until [Issue #7057](https://github.com/ValveSoftware/Source-1-Games/issues/7057) is fixed.

```sh
steamcmd +runscript $HOME/steamcmd-scripts/update_css_ds.txt
steamcmd +runscript $HOME/steamcmd-scripts/update_tf2_ds.txt
```

### Copy over missing 64-bit files from TF2 server

```sh
cp -a $HOME/tf2-serverfiles/bin/linux64/libsteam_api.so $HOME/css-serverfiles/bin/linux64/.
cp -a $HOME/tf2-serverfiles/srcds_linux64 $HOME/tf2-serverfiles/srcds_run_64 $HOME/css-serverfiles/.
```

You can delete the `tf-serverfiles` afterwards

```sh
rm $HOME/tf2-serverfiles
```

### Symlink the 64-bit binaries to themselves

Every `*_srv.so` file in `css-serverfiles/bin/linux64/` needs to be symlinked to the same file without `_srv`.
```sh
# Example
ln -s datacache_srv.so datacache.so;
#...
ln -s vscript_srv.so vscript.so;
```

```sh
cd $HOME/css-serverfiles/bin/linux64/
for file in *_srv.so; do
  ln -s "$file" "${file/_srv/}"
done
```

### Symlink steamclient.so 64-bit binary

```sh
export steamclient64bit=$(find "$HOME" -type f -name 'steamclient.so' | grep "linux64")
mkdir -p $HOME/.steam/sdk64/ # srcds_linux64 looks for steamclient.so in this directory
ln -sf $steamclient64bit $HOME/.steam/sdk64/steamclient.so
ln -sf $steamclient64bit $HOME/css-serverfiles/bin/linux64/steamclient.so
```

### Confirm working server:

```sh
cd $HOME/css-serverfiles
# Run the one matching your game
# css
    ./srcds_run_64 -game cstrike +map de_dust2 -debug
# dods
    ./srcds_run_64 -game dods +map dod_anzio -debug
# hldm
    ./srcds_run_64 -game hl1mp +map crossfire -debug
# hl2dm
    ./srcds_run_64 -game hl2mp +map dm_lockdown -debug
```
