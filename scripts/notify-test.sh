#!/usr/bin/env bash
# notify-test.sh [normal|steam|actions|critical|burst]
case "${1:-normal}" in
  normal)   notify-send -a "Vesktop" "Alex" "¿Echamos unas partidas esta noche?" ;;
  steam)    notify-send -a "Steam" -i steam "Descarga completada" "Persona 5 Royal está listo para jugar." ;;
  actions)  notify-send -a "Sistema" -A open=Abrir -A folder=Carpeta "Captura guardada" "~/Imágenes/captura.png" & ;;
  critical) notify-send -u critical -a "Energía" "Batería crítica" "5% · conecta el cargador" ;;
  burst)    for i in 1 2 3 4 5; do notify-send -a "Prueba" "Notificación $i" "Mensaje de prueba número $i"; sleep 0.4; done ;;
  *)        echo "uso: notify-test.sh normal|steam|actions|critical|burst" ;;
esac