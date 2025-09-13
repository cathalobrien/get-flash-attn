#!/bin/bash --login
#SBATCH --job-name=build-flash-attn-v3
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=288
#SBATCH --gres=gpu:1
#SBATCH --hint=nomultithread
#SBATCH --mem=0
#SBATCH --time=4:00:00
#SBATCH -o outputs/aarch64/%x-%j.out

set -ex


# FA3 is still in beta so doesnt have releases
# Here I'm picking a recent commit which removes the need for different ABI builds
# the version is hardcoded at 3.0.0.b1 and shouldnt be changed
# but the git commit can be updated
flash_version=b3846b059bf6b143d1cd56879933be30a9f78c81
python3_minor_version=12
torch_version=2.6
cuda_version=12.8
cxx11_abi="FALSE"

wheel_dir=/ec/res4/hpcperm/naco/aifs/get-flash-attn/wheels/
echo "wheel_dir=$wheel_dir"

#create python env
source slurm/utils.sh
#builds python 3.$minor and activates a venv under TMPDIR
build_python_from_conda $python3_minor_version

module load gcc/11.4.1

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

export PYTHONNOUSERSITE=1 #dont look in ~/.local
python -m pip install --upgrade --no-cache-dir wheel setuptools packaging ninja numpy

#older torch versions arent built against cu 126
torch_minor_version=`echo  $torch_version | cut -d. -f2`
if [[ "$torch_minor_version" -lt "7"  ]]; then
python -m pip install  torch==${torch_version}.0 --index-url https://download.pytorch.org/whl/cu126
elif  [[ "$torch_minor_version" -lt "8"  ]]; then
python -m pip install  torch==${torch_version}.0 --index-url https://download.pytorch.org/whl/cu128
else
python -m pip install  torch==${torch_version}.0 --index-url https://download.pytorch.org/whl/cu129
fi

if [[ ! -d flash-attention ]]; then
git clone git@github.com:Dao-AILab/flash-attention.git
fi
cd flash-attention
git checkout $flash_version
git submodule update --init --recursive
cd hopper

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
