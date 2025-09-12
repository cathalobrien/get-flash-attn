#!/bin/bash --login
#SBATCH --job-name=build-flash-attn
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=128
#SBATCH --gres=gpu:1
#SBATCH --gpus-per-node=1
#SBATCH --mem=0
#SBATCH --qos=ng
#SBATCH --exclude=ac6-320
#SBATCH --time=4:00:00
#SBATCH -o outputs/x86/%x-%j.out

set -ex

flash_version=2.7.4.post1
python3_minor_version=11
torch_version=2.7.0

wheel_dir=/ec/res4/hpcperm/naco/aifs/get-flash-attn/wheels/x86/flash-${flash_version}/python3.${python3_minor_version}/torch${torch_version}

if [[ $python3_minor_version == "11" ]]; then
module load python3/3.11.10-01
else
echo "unsupported python version  $python3_minor_version. exiting..."
exit 0
fi
module load gcc/12.2.0
module load cuda/12.6
#export CPATH=/usr/local/apps/nvidia/24.5/Linux_x86_64/24.5/cuda/12.4/targets/x86_64-linux/include/
export CXX=g++ CC=gcc

cd $TMPDIR

if [[ ! -d  $TMPDIR/venv ]]; then
python3 -m venv $TMPDIR/venv
fi
source $TMPDIR/venv/bin/activate
pip install --no-cache-dir wheel setuptools packaging ninja torch==$torch_version numpy

if [[ ! -d flash-attention ]]; then
git clone git@github.com:Dao-AILab/flash-attention.git
fi
cd flash-attention
git checkout v${flash_version}
git submodule update --init --recursive

export FLASH_ATTN_CUDA_ARCHS="80;90" #Ampere and Hopper
export MAX_JOBS=2
export NVCC_THREADS=2
export FLASH_ATTENTION_FORCE_BUILD="TRUE"
export FLASH_ATTENTION_FORCE_CXX11_ABI="FALSE"
python setup.py clean
python setup.py bdist_wheel -vvvvv --dist-dir=dist

mkdir -p $wheel_dir
mv dist/*  $wheel_dir
