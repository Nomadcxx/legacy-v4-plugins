#!/bin/bash

CMD="$1"
shift

case "$CMD" in
  "list")
    CURRENT_PATH="$1"
    if [[ -z "$CURRENT_PATH" ]]; then
      pass ls --format=lines
    else
      pass ls --format=lines "$CURRENT_PATH"
    fi
    ;;
  "show")
    pass show "$1"
    ;;
  *)
    echo "Unknown command: $CMD"
    exit 1
    ;;
esac