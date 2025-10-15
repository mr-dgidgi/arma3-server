#!/bin/bash
## armaserver: ArmA 2/3 Linux Dedicated Server Control Script
#  (c) 2010 BIStudio
#  Adapted by DaOarge for Arma3
#  Modified by dgidgi
#
#  Version: ShellCheck-clean
#=======================================================================
#========               CONFIGURATION PARAMETERS                ========
#======== MUST BE EDITED MANUALLY TO FIT YOUR SYSTEM PARAMETERS ========
#=======================================================================

set -euo pipefail
IFS=$'\n\t'

DATETIME="$(date +"%y%m%d-%H%M%S")"

ARMA_DIR="/home/steamcmd/Steam/steamapps/common/Arma3"          # dossier Arma
CONFIG="${ARMA_DIR}/server.cfg"                                 # config serveur
CFG="${ARMA_DIR}/basic.cfg"                                     # config réseau
PORT=2302                                                       # port d'écoute
PIDFILE="${ARMA_DIR}/Arma3.pid"                                 # fichier PID
RUNFILE="${ARMA_DIR}/Arma3.run"                                 # marqueur de run
LOGFILE="${ARMA_DIR}/log/${DATETIME}.log"                       # logs serveur
SERVER="${ARMA_DIR}/arma3server"                                # exécutable
MODDIR="mods"                                                   # dossier mods
SRVMODDIR="servermods"                                          # dossier mods serveur
OTHERPARAMS="-autoInit"                                         # paramètres additionnels

#=======================================================================
cd "${ARMA_DIR}"

SCAN="$(find "${MODDIR}" -mindepth 1 -maxdepth 1 -type d -printf '%p;' | sort)"
MODS="${SCAN%;}"

#=======================================================================
SCAN="$(find "${SRVMODDIR}" -mindepth 1 -maxdepth 1 -type d -printf '%p;' | sort)"
SRVMODS="${SCAN%;}"

#=======================================================================
ulimit -c 1000000

case "${1:-}" in
    start)
        # Empêche le double démarrage
        if [[ -f "${RUNFILE}" ]]; then
            "$0" stop
        fi

        echo "Starting A3 PUBLIC server..."
        echo "go" > "${RUNFILE}"

        # Lancer le watchdog en arrière-plan
        nohup "$0" watchdog </dev/null >/dev/null 2>&1 &

        # Enregistrer le PID du serveur
        sleep 5
        pgrep -f arma3server > "${PIDFILE}" || true
        ;;

    stop)
        echo "Stopping A3 PUBLIC server..."

        if [[ -f "${RUNFILE}" ]]; then
            rm -f "${RUNFILE}"
        fi

        if [[ -f "${PIDFILE}" ]]; then
            kill -TERM "$(cat "${PIDFILE}")" || true
            sleep 1
            rm -f "${PIDFILE}" || true
        fi
        ;;

    status)
        if [[ -f "${RUNFILE}" ]]; then
            echo "A3 PUBLIC server should be running..."
        else
            echo "A3 PUBLIC server should not be running..."
        fi

        if [[ -f "${PIDFILE}" ]]; then
            PID="$(cat "${PIDFILE}")"
            echo "PID file exists (PID=${PID})..."
            if [[ -f "/proc/${PID}/cmdline" ]]; then
                echo "Server process seems to be running..."
            fi
        fi
        ;;

    check)
        echo -n "ArmA 3 directory: ${ARMA_DIR} "
        if [[ -d "${ARMA_DIR}" ]]; then
            echo "OK"
        else
            echo "MISSING!"
        fi

        echo -n "Server executable: ${SERVER} "
        if [[ -x "${SERVER}" ]]; then
            echo "OK"
        else
            echo "ERROR!"
        fi

        echo "Port number: ${PORT}"

        echo -n "Config file: ${CONFIG} "
        if [[ -f "${CONFIG}" ]]; then
            echo "OK"
        else
            echo "MISSING!"
        fi

        echo "PID file: ${PIDFILE}"
        echo "RUN file: ${RUNFILE}"
        ;;

    restart)
        if [[ -f "${PIDFILE}" ]]; then
            rm -f "${RUNFILE}" || true
            echo "Exile reboot started"
            kill -TERM "$(cat "${PIDFILE}")" || true
            sleep 2
            rm -f "${PIDFILE}" || true
            echo "Exile stopped"
            "$0" start
        else
            echo "Exile isn't started"
        fi
        ;;

    watchdog)
        # Processus de surveillance (boucle infinie tant que RUNFILE existe)
        while [[ -f "${RUNFILE}" ]]; do
            cd "${ARMA_DIR}" || exit 1
            {
                echo "WATCHDOG ($$): [$(date)] Starting server (port ${PORT})..."
                "${SERVER}" \
                    -config="${CONFIG}" \
                    -port="${PORT}" \
                    -cfg="${CFG}" \
                    -mod="${MODS}" \
                    ${OTHERPARAMS} \
                    -servermod="${SRVMODS}"
                if [[ -f "${RUNFILE}" ]]; then
                    echo "WATCHDOG ($$): [$(date)] Server died, waiting to restart..."
                else
                    echo "WATCHDOG ($$): [$(date)] Server shutdown intentional, watchdog terminating"
                fi
            } >> "${LOGFILE}" 2>&1
        done
        ;;

    *)
        echo "Usage: $0 {start|stop|restart|status|check}"
        exit 1
        ;;
esac
