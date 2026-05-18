#!/bin/bash

set -e

DATA_FILE="$1"

if [[ ! -f "$DATA_FILE" ]]; then
  echo "Error: data file not found" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required" >&2
  exit 1
fi

PASSWORD=$(jq -r '.password' "$DATA_FILE")
PATH_NAME=$(jq -r '.path' "$DATA_FILE")
FIELDS_JSON=$(jq -c '.fields' "$DATA_FILE")

rm -f "$DATA_FILE"

NUM_FIELDS=$(echo "$FIELDS_JSON" | jq '. | length')

if command -v wmenu &>/dev/null; then
  MENU_CMD="wmenu"
elif command -v wofi &>/dev/null; then
  MENU_CMD="wofi"
else
  echo "Error: wmenu or wofi is required" >&2
  exit 1
fi

while true; do
  OPTIONS=("Copy Password" "Type Password")

  IDX=2
  FIELD_KEYS=()
  FIELD_VALUES=()

  if [[ "$NUM_FIELDS" -gt 0 ]]; then
    while IFS= read -r line; do
      KEY=$(echo "$line" | jq -r '.key')
      VALUE=$(echo "$line" | jq -r '.value')
      OPTIONS+=("Copy: $KEY")
      OPTIONS+=("Type: $KEY")
      FIELD_KEYS+=("$KEY")
      FIELD_VALUES+=("$VALUE")
    done < <(echo "$FIELDS_JSON" | jq -c '.[]')
  fi

  OPTIONS+=("Cancel")

  SELECTION=$(printf '%s\n' "${OPTIONS[@]}" | $MENU_CMD -p "Pass: $PATH_NAME")

  if [[ -z "$SELECTION" ]] || [[ "$SELECTION" == "Cancel" ]]; then
    exit 0
  fi

  case "$SELECTION" in
    "Copy Password")
      printf '%s' "$PASSWORD" | wl-copy
      exit 0
      ;;
    "Type Password")
      printf '%s' "$PASSWORD" | wtype -
      exit 0
      ;;
    "Copy: "*)
      IDX_STR=$(echo "$SELECTION" | sed 's/Copy: //')
      IDX=0
      for i in "${!FIELD_KEYS[@]}"; do
        if [[ "${FIELD_KEYS[$i]}" == "$IDX_STR" ]]; then
          IDX=$i
          break
        fi
      done
      printf '%s' "${FIELD_VALUES[$IDX]}" | wl-copy
      exit 0
      ;;
    "Type: "*)
      IDX_STR=$(echo "$SELECTION" | sed 's/Type: //')
      IDX=0
      for i in "${!FIELD_KEYS[@]}"; do
        if [[ "${FIELD_KEYS[$i]}" == "$IDX_STR" ]]; then
          IDX=$i
          break
        fi
      done
      printf '%s' "${FIELD_VALUES[$IDX]}" | wtype -
      exit 0
      ;;
  esac
done