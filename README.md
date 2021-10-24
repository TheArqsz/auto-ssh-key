```
┌─┐┬ ┬┌┬┐┌─┐   ┌─┐┌─┐┬ ┬   ┬┌─┌─┐┬ ┬
├─┤│ │ │ │ │───└─┐└─┐├─┤───├┴┐├┤ └┬┘
┴ ┴└─┘ ┴ └─┘   └─┘└─┘┴ ┴   ┴ ┴└─┘ ┴ 
```

# auto-ssh-key
Automatically create ssh keys and upload them to remote server via password-based ssh connection

## Usage

```bash
./auto-ssh-key.sh -u USER -p -i IP...
```
or
```bash
./auto-ssh-key.sh -u USER --key myprivatekey_id_rsa -i IP...
```
### Mandatory arguments:
| Argument | Definition |
| :-------------: | :-------------: |
| `-u`, `--user` | Specifies username |
| `-i`, `--ip` | Specifies IP or domain |
| `-p`, `--password` | Prompt for ssh password |
OR
| `--key` | Specifies existing SSH key |

### Optional arguments:

| Argument | Definition | Default value |
| :-------------: | :-------------: | :-------------: |
| `-s`, `--port` | Specifies ssh port | 22 |
| `-f`, `--file` | Specifies ssh key filename | `current-timestamp_id_rsa` |
| `-h`, `--help` | Displays help | - |
| `-l`, `--logs` | Specifies error log file | `auto-ssh-key.sh.log` |
| `-t`, `--type` | Specifies type of a SSH key | rsa |
| `-b`, `--bytes` | Specifies the number of bits in the key to create | 4096 |
| `--no-prune` | Do not remove generated keys if error occured. Do not remove public key if script finished properly | - |
