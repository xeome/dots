#!/bin/sh
# init variables
version="v2020.10.27"
ENDPOINT="https://ttm.sh"
flag_options=":hvcufe:s::"
flag_version=0
flag_help=0
flag_file=0
flag_url=0
flag_colors=0
flag_ext=0
data=""
EXT=""
# help message available via func
show_help() {
  cat > /dev/stdout << END
pb [options] filename
or
(command-with-stdout) | pb
Uploads a file or data to the tilde 0x0 paste bin
OPTIONAL FLAGS:
  -h                        Show this help
  -v                        Show current version number
  -f                        Explicitly interpret stdin as filename
  -c                        Pretty color output
  -u                        Shorten URL
  -s server_address         Use alternative pastebin server address
  -e bin_extension          Specify a binary file extension used in the upload
END
}
show_usage() {
  cat > /dev/stdout << END
usage: pb [-hfvcux] [-s server_address] filename
END
}
# helper for program exit, supports error codes and messages
die () {
  msg="$1"
  code="$2"
  # exit code defaults to 1
  if printf "%s" "${code}" | grep -q '^[0-9]+$'; then
    code=1
  fi
  # output message to stdout or stderr based on code
  if [ -n "${msg}" ]; then
    if [ "${code}" -eq 0 ]; then
      printf "%s\\n" "${msg}"
    else
      printf "%s%s%s\\n" "$ERROR" "${msg}" "$RESET" >&2
    fi
  fi
  exit "${code}"
}
# attempt to parse options or die
if ! parsed=$(getopt ${flag_options} "$@"); then
  printf "pb: unknown option\\n"
  show_usage
  exit 2
fi
# handle options
eval set -- "${parsed}"
while true; do
  case "$1" in
    -h|?)
      flag_help=1
      ;;
    -v)
      flag_version=1
      ;;
    -c)
      flag_colors=1
      ;;
    -f)
      flag_file=1
      ;;
    -e)
      shift
      flag_ext=1
      EXT="$1"
      ;;
    -s)
      shift
      ENDPOINT="$1"
      ;;
    -u)
      flag_url=1
      ;;
    --)
      shift
      break
      ;;
    *)
      die "Internal error: $1" 3
      ;;
  esac
  shift
done
# display current version
if [ ${flag_version} -gt 0 ]; then
  printf "%s\\n" "${version}"
  die "" 0
fi
# display help
if [ ${flag_help} -gt 0 ]; then
  show_help
  die "" 0
fi
# is not interactive shell, use stdin
if [ -t 0 ]; then
  flag_file=1
else
  if [ ${flag_ext} -gt 0 ]; then
    # short-circuit stdin access to ensure binary data is transferred to curl
    curl -sF"file=@-;filename=null.${EXT}" "${ENDPOINT}" < /dev/stdin
    exit 0
  else
    data="$(cat < /dev/stdin )"
  fi
fi
# if data variable is empty (not a pipe) use params as fallback
if [ -z "$data" ]; then
  data="$*"
fi
# Colors
if [ ${flag_colors} -gt 0 ]; then
  SUCCESS=$(tput setaf 190)
  ERROR=$(tput setaf 196)
  RESET=$(tput sgr0)
else
  SUCCESS=""
  ERROR=""
  RESET=""
fi
# URL shortening reference
# If URL mode detected, process URL shortener and end processing without
# checking for a file to upload to the pastebin
if [ ${flag_url} -gt 0 ]; then
  if [ -z "${data}" ]; then
    # if no data
    # print error message
    printf "%sProvide URL to shorten%s\\n" "$ERROR" "$RESET"
  else
    # shorten URL and print results
    result=$(curl -sF"shorten=${data}" "${ENDPOINT}")
    printf "%s%s%s\\n" "$SUCCESS" "$result" "$RESET"
  fi
  die "" 0
fi

