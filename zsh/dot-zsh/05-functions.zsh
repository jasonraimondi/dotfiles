# open github aka ogh
function ogh() {
  local REMOTE_NAME="$(git remote -v | awk '{print $2}' | head -n 1)"

  if [[ $REMOTE_NAME == *"github"* ]]; then
    local URL="https://github.com/${REMOTE_NAME:15:-4}"
    echo "Opening $URL"
    open "$URL"
  else
    echo "This doesnt look like a github repository"
  fi
}

function e() {
  if [ "$1" = "" ] ; then
    exec $EDITOR .
  else
    exec $EDITOR "$1"
  fi
}

function latest() {
  curl -sL "https://api.github.com/repos/$1/releases/latest" | jq -r ".tag_name"
}

function versions() {
    echo "node: $(node --version)"
    echo "npm: $(npm --version)"
    echo "cargo: $(cargo --version)"
    echo "ruby: $(ruby --version)"
}

function lt() { 
  ls -ltrsa "$@" | tail; 
}

function remove_lines_from() {
  # removes lines from $1 if they appear in $2
  grep -F -x -v -f $2 $1; 
}


function circular-deps() {
  if [ $# -eq 0 ]
  then
    echo "src dir required"
    return 1;
  fi

  pnpx madge --circular --extensions ts "$1"
}

# function blast-with-requests() {
#   local NUM_OF_REQUESTS=200
#   if [ test -e $2 ]; then
#       local NUM_OF_REQUESTS=$2
#   fi
#   # seq 1 1000000 | xargs -n1 -P100 curl --silent --output /dev/null "https://hitrecord:staging@staging.hitrecordvr.tv"
#   seq 1 $NUM_OF_REQUESTS | xargs -n1 -P10  curl --silent --output /dev/null "$1"
# }

function slugify() {
  echo "$1" | sed -E s/[^a-zA-Z0-9]+/-/g | sed -E s/^-+\|-+$//g | tr "[:upper:]" "[:lower:]"
}

function mini-img() {
  local RESIZE=""
  if [ test -e $2 ]; then
    local RESIZE="-resize $2x"
  fi
  convert -strip -interlace Plane -gaussian-blur 0.05 "$RESIZE" -quality 85% "$1" "$1.min.jpg"
  exit 0
}

# Show all the names (CNs and SANs) listed in the SSL certificate
# for a given domain
function getcertnames() {
  if [ -z "${1}" ]; then
    echo "ERROR: No domain specified.";
    return 1;
  fi;

  local domain="${1}";
  echo "Testing ${domain}…";
  echo ""; # newline

  local tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
    | openssl s_client -connect "${domain}:443" -servername "${domain}" 2>&1);

  if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
    local certText=$(echo "${tmp}" \
      | openssl x509 -text -certopt "no_aux, no_header, no_issuer, no_pubkey, \
      no_serial, no_sigdump, no_signame, no_validity, no_version");
    echo "Common Name:";
    echo ""; # newline
    echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//" | sed -e "s/\/emailAddress=.*//";
    echo ""; # newline
    echo "Subject Alternative Name(s):";
    echo ""; # newline
    echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
      | sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2;
    return 0;
  else
    echo "ERROR: Certificate not found.";
    return 1;
  fi;
}

function sidebyside() {
  local OUTPUT="${3:-ouput.png}"
  if [ -z "${2}" ]; then
    echo "requires two inputs";
    return 1;
  fi;
  montage "$1" "$2" -tile 2x1 -geometry +20+20 -background none "$OUTPUT"
}

# Run `dig` and display the most useful info
function digga() {
  dig +nocmd "$1" any +multiline +noall +answer;
}

function targz() {
  local tmpFile="${@%/}.tar";
  tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1;

  size=$(
    stat -f"%z" "${tmpFile}" 2> /dev/null; # macOS `stat`
    stat -c"%s" "${tmpFile}" 2> /dev/null;  # GNU `stat`
  );

  local cmd="";
  if (( size < 52428800 )) && hash zopfli 2> /dev/null; then
    # the .tar file is smaller than 50 MB and Zopfli is available; use it
    cmd="zopfli";
  else
    if hash pigz 2> /dev/null; then
      cmd="pigz";
    else
      cmd="gzip";
    fi;
  fi;

  echo "Compressing .tar ($((size / 1000)) kB) using \`${cmd}\`…";
  "${cmd}" -v "${tmpFile}" || return 1;
  [ -f "${tmpFile}" ] && rm "${tmpFile}";

  zippedSize=$(
    stat -f"%z" "${tmpFile}.gz" 2> /dev/null; # macOS `stat`
    stat -c"%s" "${tmpFile}.gz" 2> /dev/null; # GNU `stat`
  );

  echo "${tmpFile}.gz ($((zippedSize / 1000)) kB) created successfully.";
}
