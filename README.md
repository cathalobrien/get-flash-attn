# get-flash-attn
A script which parses your python environment and installs the correct flash-attention wheel.

tri dao et al created flash-attention, which is released under a BSD-3 license. This script retrieves and installs pre-built flash-attention wheels. 

## How to
This script works for systems with nvidia GPUs. AMD GPUs and CPUs are not supported as the pre-built wheels are not available on the flash-attn github page.

```bash
# setup
git clone git@github.com:cathalobrien/get-flash-attn.git
cd get-flash-attn

# install flash attn
source /path/to/venv/bin/activate #activate your venv/conda/uv env
./get-flash-attn
```

## Command line args
The following command line args are supported
```bash
-s|--source # which provider to download the wheels from. possible values are "all;tridao;naco". "all" will dynamically select provider based on versions
-v|--flash-attn-version $version # Which version of flash attention to install. defaults to '2.7.4.post1'
--offline # Prints instructions to install on an airgapped system e.g. MN5
--dryrun # Dryrun. prints commands instead of running them
--get-wheel # Downloads the wheel to your cwd and quits
--uv # Install into a UV env
--force-reinstall # Forces pip to reinstall flash-attn
--verbose # Verbose mode. all commands will be printed before execution, and wget and pip are not silenced
```
For legacy reasons, the env vars 'UV', 'OFFLINE' and 'DRYRUN' can be set to '1' to set their relevant flags.

### UV
To install into a uv env, run the script as shown
```bash
./get-flash-attn --uv
#UV=1 ./get-flash-attn #legacy
```

### Offline installs
The script works for systems without internet access. It will automatically detect when internet is not available and then print the URL to the correct wheel for your syetm. The you can follow the example below to install it on your system

```bash
#offline demo

# On the system without internet, run:
./get-flash-attn
# prints 'wget https://github.com/Dao-AILab/flash-attention/releases/download/...whl'

# on a system with internet, run:
wget https://github.com/Dao-AILab/flash-attention/releases/download/...whl
scp ...whl system_without_internet:

# On the system without internet, run:
pip install ...whl
```

## Building wheels
The repo includes slurm scripts to build x86 and aarch64 wheels.

To see which configurations have begun:
```
grep -r "wheel_dir" outputs/ | awk '{print $2}' | uniq | sort
```

To see which build configurations were successful, and the wheels locations:
```
grep -r "mv dist" outputs/ | awk '{print $4}' | uniq | sort
```

## TODO
* modify built wheels names to include cuda, torch and ABI information in build
* add an option to build with ABI true/false
* add wheel coverage matrix
* build ABI true
* store cuda minor version in naco wheels
