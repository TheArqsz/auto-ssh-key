#!/usr/bin/env bash
# Bash script that generates ssh key and upload it to remote server
#
# Copyright 2021 TheArqsz

# sshpass is needed for smooth passing password to ssh commands
if ! command -v sshpass &> /dev/null
then
   echo "sshpass could not be found"
   echo "Use: sudo apt install sshpass"
   exit 1
fi

# Print usage of this script
help()
{
   echo "Usage: ./`basename "$0"` -u USER -p PASSWORD -i IP..."
   echo "Generate SSH keys and copy them to remote"
   echo
   echo "Mandatory arguments:"
   echo "   -u, --user        Specifies username"
   echo "   -i, --ip          Specifies IP or domain"
   echo "   -p, --password    Prompt for ssh password"
   echo
   echo "Optional arguments:"
   echo "   -s, --port        Specifies ssh port (default: 22)"
   echo "   -f, --file        Specifies ssh key filename (default: current-timestamp_id_rsa)"
   echo "   -h, --help        Displays this help"
   echo "   -l, --logs        Specifies error log file (default: `basename "$0"`.log)"
   echo "   -t, --type        Specifies type of a SSH key (default: rsa)"
   echo "   -b, --bytes       Specifies the number of bits in the key to create (default: 4096)"
   echo "   --no-prune        Do not remove generated keys if error occured. Do not remove public key if script finished properly"
   echo
}

# Print banner with the name of the script 
banner()
{
cat << EOF

┌─┐┬ ┬┌┬┐┌─┐   ┌─┐┌─┐┬ ┬   ┬┌─┌─┐┬ ┬
├─┤│ │ │ │ │───└─┐└─┐├─┤───├┴┐├┤ └┬┘
┴ ┴└─┘ ┴ └─┘   └─┘└─┘┴ ┴   ┴ ┴└─┘ ┴ 

EOF
}

# Set global variables and empty error log file
error_log_file=`basename "$0"`.log
echo `date` > $error_log_file
error_log_file=$(realpath $error_log_file)
prune=1
ssh_port=22
ssh_key_type=rsa
ssh_key_bytes=4096
current_timestamp=$(date +"%s")
key_name=${current_timestamp}_id_rsa

# Traps
failure() {
	local lineno=$1
	local msg=$2
	if [ "$1" != "0" ]; then
		echo "	> [`date`] Failed at line $lineno: '$msg'" >> $error_log_file
	fi
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

cleanup() {
	if [ "$?" = "0" ]; then
		echo "Script finished - cleaning logs"
		read -p "Press CTRL-C to interrupt cleaning or wait 5 sec to continue" -t 5
      echo
		rm $error_log_file 2>/dev/null
	fi
}
trap cleanup EXIT

function ctrl_c() {
	echo
	echo "Interrupting..."
	exit 1
}
trap ctrl_c INT

# Loop that sets arguments for the script
while [ -n "$1" ]; do 
	case "$1" in
	   -h|--help) 
         banner
         help
         exit;;
   	-u|--user)
         username=$2
         shift
         ;;
   	-i|--ip)
         ip=$2
         shift
         ;;
   	-p|--password)
         echo "WARNING You will be asked for a password - no ouput will be shown."
         read -s -p "Enter password: " password
         shift 0
         ;;
   	-s|--port)
         ssh_port=$2
         shift
         ;;
   	-f|--file)
         key_name=$2
         shift
         ;;
   	-l|--logs)
         log_file=$2
         shift
         ;;
   	-t|--type)
         ssh_key_type=$2
         shift
         ;;
   	-b|--bytes)
         ssh_key_bytes=$2
         shift
         ;;
   	--no-prune)
         prune=0
         shift 0
         ;;
      *) 
         echo "Option '$1' is not recognized"
         echo
         help
         exit 1
         ;;
      esac
      shift
done

# Check mandatory arguments
if [ -z "$username" ]; then
   echo "Username cannot be empty - specify username"
   exit 1
fi
if [ -z "$ip" ]; then
   echo "Target cannot be empty - specify IP or domain"
   exit 1
fi
if [ -z "$password" ]; then
   echo "Password cannot be empty - use -p"
   exit 1
fi

# Show banner before the main part of script 
banner

# Check if script can connect to ssh server with password
sshpass -p $password ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $username@$ip -p $ssh_port exit 2>>$error_log_file
if [ $? != "0" ]; then
   echo "Cannot confirm that SSH server is working"
   echo "Check your credentials, port or server status"
   echo "Check logs in $error_log_file"
   exit 1
else
   echo "Connected as $username to ssh://$ip:$ssh_port"
   echo
fi

# Generate SSH keys
ssh-keygen -q -t $ssh_key_type -b $ssh_key_bytes -N '' -f $key_name -C ${username}-secret_token 2>$error_log_file
if [ $? != "0" ]; then
   echo "Cannot generate SSH keys named $key_name"
   echo "Check logs in $error_log_file"
   if [ $prune = "1" ]; then
      echo "Removing all generated keys"
      rm ${key_name}*
   fi
   exit 1
else
   echo "Generated SSH keys - $key_name and ${key_name}.pub"
   echo
fi

# Copy public key to remote server
sshpass -p $password ssh-copy-id -o StrictHostKeyChecking=no -p $ssh_port -i ${key_name} $username@$ip 2>>$error_log_file 1>>$error_log_file
if [ $? != "0" ]; then
   echo "Cannot copy public key ${key_name}.pub"
   echo "Check logs in $error_log_file"
   if [ $prune = "1" ]; then
      echo "Removing all generated keys"
      rm ${key_name}*
   fi
   exit 1
else
   echo "Public key ${key_name}.pub copied successfuly to remote server"
   if [ $prune = "1" ]; then
      echo "Removing public key from local file system"
      rm ${key_name}.pub
   fi
   echo
fi

# Check if SSH keys are properly set
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i $key_name $username@$ip -p $ssh_port exit 2>>$error_log_file
if [ $? != "0" ]; then
   echo "Cannot connect to SSH server"
   echo "Check logs in $error_log_file"
   if [ $prune = "1" ]; then
      echo "Removing all generated keys"
      rm ${key_name}*
   fi
   exit 1
else
   echo "SSH keys are working properly"
   echo
   echo "Your SSH key:  "
   echo "   ${key_name}"
   echo
   echo "You can log in to you server with:"
   echo "   ssh -p ${ssh_port} -i ${key_name} ${username}@${ip}"
fi
