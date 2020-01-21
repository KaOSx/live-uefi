#!/bin/bash

# Configs
source /usr/share/kdeosiso/functions/colors
.  /usr/share/kdeosiso/functions/messages

# Variables
CURRENTDIR=$(pwd)
ARCHITECTURE=$(echo $1)
WORKDIR=$(echo $2)

echo " "
if [ -z "${ARCHITECTURE}" ] ; then
    ARCHITECTURE=$(pacman -Qi bash | grep "Architecture" | cut -d " " -f 6)
    msg  "Architecture not supplied, defaulting to host's architecture: ${ARCHITECTURE}"
fi

if [ "${ARCHITECTURE}" != "i686" ] && [ "${ARCHITECTURE}" != "x86_64" ] ; then
    ARCHITECTURE=$(pacman -Qi bash | grep "Architecture" | cut -d " " -f 6)
    msg  "Incorrect arquitecture, defaulting to host's architecture: ${ARCHITECTURE}"
fi


if [ -z "${WORKDIR}" ] ; then
    WORKDIR="work-${ARCHITECTURE}"
    msg  "Working dir not supplied, defaulting to ${WORKDIR}/"
fi

if [ ! -e overlay-pkgs.${ARCHITECTURE} ] ; then
    echo " "
    error "the config file overlay-pkgs.${ARCHITECTURE} is missing"
    echo " "
    exit 
fi

# Create TempDir and move into it
echo -e "$_r >$_W Updating overlay packages ... $_n"
mkdir -p ${CURRENTDIR}/${WORKDIR}/overlay-pkgs/opt/kdeos/pkgs &>/dev/null
#echo -e -n "$_r >$_W Removing temporary directories ... $_n"
#rm -rf temp &>/dev/null
echo -e "$_g done $_n"

_overlaypkgs=$(sed -e 's/\#.*//' -e 's/[ ^I]*$$//' -e '/^$$/ d' overlay-pkgs.${ARCHITECTURE})

# Get pkgs
echo -e -n "$_r >$_W Getting packages ... $_n"
for _p in ${_overlaypkgs[@]} ; do
    _rep=$(echo ${_p} | cut -d: -f1)
    _pkg=$(echo ${_p} | cut -d: -f2)
    #rsync -avq --include "${_rep}/" --include "${_pkg}*" --exclude '*' kaosx.tk::kaos ${CURRENTDIR}/${WORKDIR}/overlay-pkgs/opt/kdeos/pkgs/
    #rsync -avq --include main/ --include nvidia-3* --exclude '*' kaosx.tk::kaos ${CURRENTDIR}/${WORKDIR}/overlay-pkgs/opt/kdeos/pkgs/
    #rsync -avq --include main/ --include nvidia-utils* --exclude '*' kaosx.tk::kaos ${CURRENTDIR}/${WORKDIR}/overlay-pkgs/opt/kdeos/pkgs/
    #rsync -avq --include apps/ --include partitionmanager-1* --exclude '*' kaosx.tk::kaos ${CURRENTDIR}/${WORKDIR}/overlay-pkgs/opt/kdeos/pkgs/
    #_repos=("${_repos[@]}" "${_rep}")
done
echo -e "$_g done $_n"

# Remove duplicated repos
#IFS='
#'
#_repos=( $( printf "%s\n" "${_repos[@]}" | awk 'x[$0]++ == 0' ) )

# Remove old stuff
#echo -e -n "$_r >$_W Removing old packages ... $_n"
#rm -rf ${CURRENTDIR}/${WORKDIR}/overlay-pkgs/opt/kdeos/pkgs/*.pkg* &>/dev/null
#echo -e "$_g done $_n"

# Move downloaded packages into overlay
#echo -e -n "$_r >$_W Moving new packages into overlay ... $_n"
#for _re in ${_repos[@]} ; do
#    mv -v ${CURRENTDIR}/temp/${_re}/$ARCHITECTURE/*.pkg.tar.*z ${CURRENTDIR}/${WORKDIR}/overlay-pkgs/opt/kdeos/pkgs/ &>/dev/null
#done
#echo -e "$_g done $_n"
#echo " "

# clean up
#echo -e -n "$_r >$_W Cleaning up ... $_n"
#rm -rf temp &>/dev/null
#echo -e "$_g done $_n"
#echo " "

# show packages
echo -e "$_r >$_W List of fetched packages: $_n"
echo " "
ls -1 ${CURRENTDIR}/${WORKDIR}/overlay-pkgs/opt/kdeos/pkgs/

echo " "
echo -e "$_g >$_W All done ! $_n"
echo " "

# Create /etc/nvidia-drv.conf
#echo -e -n "$_r >$_W Create /etc/nvidia-drv.conf ... $_n"
#mkdir -p ${CURRENTDIR}/${WORKDIR}/overlay-pkgs/etc
#NVIDIA_DRV_VER=`ls -1 ${CURRENTDIR}/${WORKDIR}/overlay-pkgs/opt/kdeos/pkgs/ | grep nvidia-2 | cut -d- -f2 | cut -d. -f1`
#echo "NVIDIA_DRV_VER=\"${NVIDIA_DRV_VER}\"" > ${CURRENTDIR}/${WORKDIR}/overlay-pkgs/etc/nvidia-drv.conf
#echo -e "$_g done $_n"

