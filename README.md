# get-flash-attn
A script which parses your python environment and grabs the correct flash-attention wheel from github

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

### UV
To install into a uv env, run the script as shown
```bash
UV=1 ./get-flash-attn
```
