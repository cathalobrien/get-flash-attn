#!/bin/bash --login
#SBATCH --job-name=build-flash-attn
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=288
#SBATCH --gres=gpu:1
#SBATCH --hint=nomultithread
#SBATCH --mem=0
#SBATCH --time=4:00:00
#SBATCH -o outputs/aarch64/%x-%j.out

set -ex

flash_version=2.7.4.post1
python3_minor_version=12
torch_version=2.8
cuda_version=12.8
cxx11_abi="FALSE"

wheel_dir=/ec/res4/hpcperm/naco/aifs/get-flash-attn/wheels/
echo "wheel_dir=$wheel_dir"

if [[ $python3_minor_version == "12" ]]; then
module load  python3/3.12.9-01
else
echo "unsupported python version  $python3_minor_version. exiting..."
exit 0
fi

module load gcc/11.4.1
#export CXX=g++ CC=gcc

if [[ $cuda_version == "12.9" ]]; then
	module load  cuda/$cuda_version 
	module load nvidia/25.5
elif  [[  $cuda_version == "12.8" ]]; then
  	module load  cuda/$cuda_version
        module load nvidia/25.3
else
	echo "unsupported cuda version $cuda_version. exiting..."
	exit 0
fi
if [[ $CUDA_HOME == "" ]]; then
	echo "CUDA_HOME is not set. please set it. exiting..."
	exit 0
fi

cd $TMPDIR

if [[ ! -d  $TMPDIR/venv ]]; then
python3 -m venv $TMPDIR/venv
fi
source $TMPDIR/venv/bin/activate
pip install --no-cache-dir wheel setuptools packaging ninja numpy

#older torch versions arent built against cu 126
torch_minor_version=`echo  $torch_version | cut -d. -f2`
if [[ "$torch_minor_version" -lt "7"  ]]; then
pip install  torch==${torch_version}.0 --index-url https://download.pytorch.org/whl/cu126
elif  [[ "$torch_minor_version" -lt "8"  ]]; then
pip install  torch==${torch_version}.0 --index-url https://download.pytorch.org/whl/cu128
else
pip install  torch==${torch_version}.0 --index-url https://download.pytorch.org/whl/cu129
fi

if [[ ! -d flash-attention ]]; then
git clone git@github.com:Dao-AILab/flash-attention.git
fi
cd flash-attention
git checkout v${flash_version}
git submodule update --init --recursive

export FLASH_ATTN_CUDA_ARCHS="90" #hopper
export MAX_JOBS=2
export NVCC_THREADS=2
export FLASH_ATTENTION_FORCE_BUILD="TRUE"
export FLASH_ATTENTION_FORCE_CXX11_ABI=$cxx11_abi

python setup.py clean
python setup.py bdist_wheel -vvvvv --dist-dir=dist

mkdir -p $wheel_dir
cuda_minor_version=${cuda_version%%.*}
#credit to https://github.com/Dao-AILab/flash-attention/blob/e980f0f6e15ae3a7bc2a29e5610e8a9bfe25f7a6/.github/workflows/_build.yml#L178
tmpname=cu${cuda_minor_version}torch${torch_version}cxx11abi${cxx11_abi}
wheel_name=$(ls dist/*whl | xargs -n 1 basename | sed "s/-/+$tmpname-/2")
cp  dist/*whl $wheel_dir/$wheel_name
echo "Wheel saved at $wheel_dir/$wheel_name"
