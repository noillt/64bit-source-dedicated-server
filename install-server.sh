#!/usr/bin/bash

set -o nounset
set -o errtrace
set -o pipefail
set -e

IFS=$'\n\t'
ME="$(basename "${0}")"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export SCRIPT_DIR=${SCRIPT_DIR%/*}

usage() {
  cat <<HEREDOC

 ██████╗ ██╗  ██╗██████╗ ███████╗██████╗ ███████╗
██╔════╝ ██║  ██║██╔══██╗██╔════╝██╔══██╗██╔════╝
███████╗ ███████║██████╔╝███████╗██║  ██║███████╗
██╔═══██╗╚════██║██╔══██╗╚════██║██║  ██║╚════██║
╚██████╔╝     ██║██████╔╝███████║██████╔╝███████║
 ╚═════╝      ╚═╝╚═════╝ ╚══════╝╚═════╝ ╚══════╝

Quick installation of 64-bit Source Dedicated Server

Requirements: libncurses5 libncurses5:i386 lib32z1

Usage:
    ./${ME} <css/dods/hl2dm/hldm>

HEREDOC
}

if [ $# -ne 1 ]; then
  usage
  exit 1
else
  case "$1" in
  css|dods|hl2dm|hldm)
    GAMESERVER=$1
    ;;
  *)
    usage
    exit 1
    ;;
  esac
fi

STEAMCMDBIN="/usr/games/steamcmd"
TF2DIR="$HOME/tf2-serverfiles"
DSDIR=""

prepare() {
  DSDIR="$HOME/$GAMESERVER-serverfiles"

  # Check if steamcmd installed and/or accessible
  if command -v steamcmd >/dev/null 2&>1; then
    STEAMCMDBIN=$(command -v steamcmd)
  elif result=$(find "$HOME" -type f -name 'steamcmd' 2>/dev/null | head -n 1) && [ -n "$result" ]; then
    STEAMCMDBIN="$result"
  else
    echo "SteamCMD not found. Please install following this guide: https://developer.valvesoftware.com/wiki/SteamCMD#Linux"
    exit 1
  fi

  echo "SteamCMD found at $STEAMCMDBIN. Continuing..."
}

fetch_server_files() {
  echo "Starting installation of $GAMESERVER dedicated server!"
  # Update steamcmd-scripts to correct home dir
  echo "Confirm steamcmd scripts are correct..."
  for _steamcmdscriptfile in $SCRIPT_DIR/steamcmd-scripts/*; do
    sed -i "s#/home/server/#/home/${USER}/#g" "$_steamcmdscriptfile"
  done

  if [ -d "$DSDIR" ]; then
    echo "$DSDIR already contains files. Exiting..."
    exit 1;
  fi

  echo "Starting to download server files using steamcmd"
  # Fetch required game server and tf2 server files
  "$STEAMCMDBIN" +runscript "$HOME/steamcmd-scripts/update_${GAMESERVER}_ds.txt" && \
    echo "$DSDIR successfully downloaded!"

  if [ -d "$TF2DIR" ]; then
    echo "$TF2DIR already contains files. Validating..."
  fi
  "$STEAMCMDBIN" +runscript "$HOME/steamcmd-scripts/update_tf2_ds.txt" && \
    echo "$TF2DIR successfully downloaded!"
}

copy_64bit() {
  echo "Copying libsteam_api.so..."
  cp -a "$TF2DIR/bin/linux64/libsteam_api.so" \
    "$DSDIR/bin/linux64/."

  echo "Copying srcds binaries..."
  cp -a "$HOME/tf2-serverfiles/srcds_linux64" "$HOME/tf2-serverfiles/srcds_run_64" \
    "$DSDIR/."
}

remove_tf2() {
  echo "Removing $TF2DIR..."
  [ -f "$DSDIR/srcds_linux64" ] && rm -r "$HOME/tf2-serverfiles" || \
    # You should never see this message
    echo "$DSDIR is missing 64-bit binaries. Cannot remove tf2-serverfiles"
}

symlink_binaries() {
  cd "$DSDIR/bin/linux64"

  for file in *_srv.so; do
    echo "Symlinking \"$file\" to \"${file/_srv/}"
    ln -s "$file" "${file/_srv/}"
  done
}

steamclient_binary() {
  echo "Looking for steamclient.so and symlinking it..."
  local _steamclient64bit=$(find "$HOME" -type f -name 'steamclient.so' | grep "linux64" | head -n 1)
  if [ ! -n $_steamclient64bit ]; then
    echo "Could not locate 64-bit steamclient.so binary. Exiting..."
    exit 1
  fi

  mkdir -p "$HOME/.steam/sdk64/" # srcds_linux64 looks for steamclient.so in this directory
  ln -sf "$_steamclient64bit" "$HOME/.steam/sdk64/steamclient.so"
  ln -sf "$_steamclient64bit" "$DSDIR/bin/linux64/steamclient.so"
}

main() {
  prepare
  fetch_server_files
  copy_64bit
  remove_tf2
  symlink_binaries
  steamclient_binary

  SRCDSGAME=""
  case "$GAMESERVER" in
    css) SRCDSGAME="cstrike"; SRCDSMAP="de_dust2";;
    dods) SRCDSGAME="dod"; SRCDSMAP="dod_anzio";;
    hl2dm) SRCDSGAME="hl2mp"; SRCDSMAP="dm_lockdown";;
    hldm) SRCDSGAME="hl1mp"; SRCDSMAP="crossfire";;
    *) ;;
  esac

  cat <<SUCESSMSG
# --------------------------------------------------- #

Successfully installed $GAMESERVER dedicated server
 to $DSDIR!

Confirm the server starts and runs without issue:
  $ cd $DSDIR
  $ ./srcds_run_64 -game $SRCDSGAME +map $SRCDSMAP -debug

# --------------------------------------------------- #
SUCESSMSG

}

main "$@"
