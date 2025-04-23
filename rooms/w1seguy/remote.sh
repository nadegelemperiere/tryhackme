# Trap signals to cleanup on exit or interruption
trap cleanup EXIT INT TERM
#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.75.133"
attack_ip="10.6.45.13"
result_folder="/media/psf/Home/Work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - KEY"

inpipe=$(mktemp -u)
outpipe=$(mktemp -u)
# Ensure old pipes are removed before creating new ones
rm -f $inpipe $outpipe
mkfifo $inpipe $outpipe

nc $target_ip 1337 < $outpipe > $inpipe &
nc_pid=$!
exec 3> $outpipe

echo "--> Connected"

cleanup() {
    echo "--> Cleaning"
    kill $nc_pid 2>/dev/null
    rm -f $inpipe $outpipe
}

first=true
# Loop reading from inpipe, feeding into python, sending back to nc via outpipe
while true; do
    if ! read -r line < $inpipe; then
        echo "Connection closed or read failed"
        break
    fi

    [ -z "$line" ] && continue

    echo $line

    message=$(echo $line | sed -n 's/.*flag 1: \(.*\).*/\1/p')

    # Call python processor with line as input
    if $first; then
        key=$(python3 $scriptpath/key.py $message)
        flag=$(python3 $scriptpath/flag.py $message $key)
        echo "--> Key is $key"
        echo "--> Flag is $flag"
        echo $key > $outpipe
        first=false
    fi
    
done

# Cleaning handled by cleanup trap