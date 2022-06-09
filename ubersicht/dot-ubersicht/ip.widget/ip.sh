#!/bin/bash

# Array of interfaces
interfaces=()

# Function: Calculate CIDR
mask2cidr() {
    nbits=0
    IFS=.
    for dec in $1 ; do
        case $dec in
            255) let nbits+=8;;
            254) let nbits+=7;;
            252) let nbits+=6;;
            248) let nbits+=5;;
            240) let nbits+=4;;
            224) let nbits+=3;;
            192) let nbits+=2;;
            128) let nbits+=1;;
            0);;
            *);;
        esac
    done
    echo $nbits
}

# Get WAN address
WAN=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null);
[ $? -eq 0 ] && [[ -n $WAN ]] && interfaces+=("{\"iface\":\"WAN\",\"address\":\"$WAN\"}")

# Get Local interfaces
while read line; do 
    # Interface name
    iname=$(echo $line | awk -F  "(, )|(: )|[)]" '{print $2}')
    # Interface reference
    iface=$(echo $line | awk -F  "(, )|(: )|[)]" '{print $4}')
	# If interface has a valid ref, check if it's active.
    if [ -n "$iface" ]; then
        ifconfig $iface 2>/dev/null | grep 'status: active' > /dev/null 2>&1
        # If exitcode is zero, get IP and add to interfaces array.
        if [ $? -eq 0 ]; then
            packet=$(ipconfig getpacket $iface)
            ip=$(ipconfig getifaddr $iface)
            subnet=$(echo "$packet" | grep subnet_mask | awk -F ": " '{print $2}')
            cidr=$(mask2cidr $subnet)
            router=$(echo "$packet" | grep router | awk -F "{|}" '{print $2}')

            interfaces+=("{\"iface\":\"$iname\",\"address\":\"$ip\",\"subnet\":\"$subnet\",\"cidr\":\"$cidr\",\"router\":\"$router\"}")
        fi
    fi
done <<< "$(networksetup -listnetworkserviceorder | grep 'Hardware Port')"

# Output interfaces in JSON format
echo "{\"interfaces\":[$(printf '%s\n' $(IFS=,; echo "${interfaces[*]}"))]}" | tr -d '\n'
