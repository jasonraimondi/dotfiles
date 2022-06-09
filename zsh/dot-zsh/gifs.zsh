
# https://askubuntu.com/a/654305

function gifopt() {
    # args: $input_file ($loss_level)
    if [ -z "$2" ]
    then
        # use default of 30
        local loss_level=30
    elif [[ "$2" =~ ^[0-9]+$ ]] && [ "$2" -ge 30 -a "$2" -le 200 ]
    then
        local loss_level=$2
    else
        echo "${2:-"Loss level parameter must be an integer from 30-200"}" 1>&2
        exit 1
    fi
    local inputgif="${1?'Missing input file parameter'}"
    local gifname="$(basename $inputgif .gif)"
    local basegifname=$(echo "$gifname" | sed 's/_reduced_x[0-9]//g')
    local outputgif="$basegifname-opt.gif"
    gifsicle -O3 --lossy="$loss_level" -o "$outputgif" "$inputgif";
    local oldfilesize=$(du -h $inputgif | cut -f1)
    local newfilesize=$(du -h $outputgif | cut -f1)
    echo "File reduced from $oldfilesize to $newfilesize as $outputgif"
}

function gifopt() {
    # args: $input_file ($loss_level)
    if [ -z "$2" ]
    then
        # use default of 30
        loss_level=30
    elif [[ "$2" =~ ^[0-9]+$ ]] && [ "$2" -ge 30 -a "$2" -le 200 ]
    then
        loss_level=$2
    else
        echo "${2:-"Loss level parameter must be an integer from 30-200"}" 1>&2
        exit 1
    fi
    local inputgif="${1?'Missing input file parameter'}"
    local gifname="$(basename $inputgif .gif)"
    local basegifname=$(echo "$gifname" | sed 's/_reduced_x[0-9]//g')
    local outputgif="$basegifname-opt.gif"
    gifsicle -O3 --lossy="$loss_level" -o "$outputgif" "$inputgif";
    local oldfilesize=$(du -h $inputgif | cut -f1)
    local newfilesize=$(du -h $outputgif | cut -f1)
    echo "File reduced from $oldfilesize to $newfilesize as $outputgif"
}

function gifspeedchange() {
  # args: $gif_path $frame_delay (1 = 0.1s)
  local orig_gif="${1?'Missing GIF filename parameter'}"
  local frame_delay=${2?'Missing frame delay parameter'}
  gifsicle --batch --delay $frame_delay $orig_gif
  local newframerate=$(echo "$frame_delay*10" | bc)
  echo "new GIF frame rate: $newframerate ms"
}
