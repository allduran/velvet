#!/usr/bin/env bash
# brightness.sh list               -> JSON [{"id","name","value"}]
# brightness.sh set <id> <percent>
cache="${XDG_RUNTIME_DIR:-/tmp}/ddc-buses"

case "$1" in
  list)
    [ "$2" = rescan ] && rm -f "$cache"
    out="["
    # Pantalla del portátil
    if b=$(brightnessctl -m 2>/dev/null); then
      p=$(cut -d, -f4 <<<"$b")
      out+="{\"id\":\"internal\",\"name\":\"PORTÁTIL\",\"value\":${p%\%}},"
    fi
    # Monitores externos (la detección es lenta, se guarda en caché)
    [ -s "$cache" ] || ddcutil detect --brief 2>/dev/null | awk '
      /^Display/         { ok = 1 }
      /^Invalid display/ { ok = 0 }
      ok && /I2C bus:/   { bus = $3; sub("/dev/i2c-", "", bus) }
      ok && /Monitor:/   { sub(/.*Monitor:[ \t]+/, ""); split($0, m, ":"); print bus "\t" m[2] }' > "$cache"
    while IFS=$'\t' read -r bus model; do
      v=$(ddcutil --bus "$bus" getvcp 10 --brief 2>/dev/null | awk '{print $4}')
      [ -n "$v" ] && out+="{\"id\":\"$bus\",\"name\":\"${model^^}\",\"value\":$v},"
    done < "$cache"
    echo "${out%,}]"
    ;;
  set)
    if [ "$2" = all ]; then
      brightnessctl -q set "$3%"
      # Todos los monitores externos a la vez
      while IFS=$'\t' read -r bus _; do
        ddcutil --bus "$bus" setvcp 10 "$3" --noverify &
      done < "$cache"
      wait
    elif [ "$2" = internal ]; then brightnessctl -q set "$3%"
    else ddcutil --bus "$2" setvcp 10 "$3" --noverify; fi
    ;;
esac