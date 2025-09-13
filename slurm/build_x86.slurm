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

flash_version=2.7.4
python3_minor_version=11
torch_version=2.6
cuda_version=12.6
cxx11_abi="FALSE"

wheel_dir=/ec/res4/hpcperm/naco/aifs/get-flash-attn/wheels/x86_64/
echo "wheel_dir=$wheel_dir"

if [[ $python3_minor_version == "11" ]]; then
module load python3/3.11.10-01
else
echo "unsupported python version  $python3_minor_version. exiting..."
exit 0
fi
module load gcc/12.2.0
if [[ $cuda_version == "12.6" ]]; then
        module load  cuda/$cuda_version
else
        echo "unsupported cuda version $cuda_version. exiting..."
        exit 0
fi
export CXX=g++ CC=gcc

cd $TMPDIR

if [[ ! -d  $TMPDIR/venv ]]; then
python3 -m venv $TMPDIR/venv
fi
source $TMPDIR/venv/bin/activate
pip install --no-cache-dir wheel setuptools packaging ninja torch==${torch_version}.0 numpy

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
export FLASH_ATTENTION_FORCE_CXX11_ABI=$cxx11_abi
python setup.py clean
python setup.py bdist_wheel -vvvvv --dist-dir=dist

mkdir -p $wheel_dir
mv dist/*  $wheel_dir
cuda_minor_version=${cuda_version%%.*}
#credit to https://github.com/Dao-AILab/flash-attention/blob/e980f0f6e15ae3a7bc2a29e5610e8a9bfe25f7a6/.github/workflows/_build.yml#L178
tmpname=cu${cuda_minor_version}torch${torch_version}cxx11abi${cxx11_abi}
wheel_name=$(ls dist/*whl | xargs -n 1 basename | sed "s/-/+$tmpname-/2")
cp  dist/*whl $wheel_dir/$wheel_name
echo "Wheel saved at $wheel_dir/$wheel_name"
