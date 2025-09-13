build_python_from_conda() {
set -eux
python_minor_version=$1
install_dir=$TMPDIR/conda

if [[ $1 == "" ]]; then
        echo "Error. usage: build_python_from_conda <python minor version>. exiting..."
        exit 0
fi

if [[ -d $install_dir ]]; then
echo "'$install_dir' exists. returning..."
return
fi

cd $TMPDIR
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-$(uname)-$(uname -m).sh -b -p "$install_dir"
rm  Miniforge3-$(uname)-$(uname -m).sh 
source "${install_dir}/etc/profile.d/conda.sh"
conda activate
conda create -c conda-forge python=3.${python_minor_version} -n venv --yes
conda activate venv
python --version
cd -
}
#build_python_from_conda 9
