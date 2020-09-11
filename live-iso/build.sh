#!/bin/bash

if [ ! -e options.conf ] ; then
    echo " "
    echo "the config file options.conf is missing, exiting..."
    echo " "
    exit
fi

if [ ! -e /usr/share/kdeosiso/functions/colors ] || [ ! -e /usr/share/kdeosiso/functions/messages ] ; then
    echo " "
    echo "missing kaos-live functions file, please run «sudo make install» inside live-iso/"
    echo " "
    exit
fi

source /usr/share/kdeosiso/functions/colors
.  /usr/share/kdeosiso/functions/messages
. options.conf

# do UID checking here so someone can at least get usage instructions
if [ "$EUID" != "0" ]; then
    echo "error: This script must be run as root."
    exit 1
fi

banner

if [ -z "${arch}" ] ; then
    arch=$(pacman -Qi bash | grep "Architecture" | cut -d " " -f 6)
    echo " "
    msg  "architecture not supplied, defaulting to host's architecture: ${arch}"
fi


if [ ! -e overlay-pkgs.${arch} ] ; then
    echo " "
    error "the config file overlay-pkgs.${arch} is missing, exiting..."
    echo " "
    exit
fi

set -e -u

pwd=`pwd`
packages=`sed -e 's/\#.*//' -e 's/[ ^I]*$$//' -e '/^$$/ d' packages.${arch}`

export LANG=C
export LC_MESSAGES=C

# Base installation (root-image)
make_root_image() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
         echo -e -n "$_r >$_W Base installation (root-image) \n $_n"
         mkkdeosiso -v -C pacman.conf -a "${arch}" -D "${install_dir}" -p "${packages}" create "${work_dir}"''
         pacman -Qr "${work_dir}/root-image" > "${work_dir}/root-image/root-image-pkgs.txt"
         cp ${work_dir}/root-image/etc/locale.gen.bak ${work_dir}/root-image/etc/locale.gen
         rm ${work_dir}/root-image/boot/grub/grub.cfg
         : > ${work_dir}/build.${FUNCNAME}
         echo -e "$_g >$_W done $_n"
    fi
}

make_boot() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
	echo -e -n "$_r >$_W Prepare ${install_dir}/boot/ \n $_n"
	mkdir -p ${work_dir}/iso/${install_dir}/boot/${arch}
        #cp ${work_dir}/root-image/boot/memtest86+/memtest.bin ${work_dir}/iso/${install_dir}/boot/${arch}/memtest
	cp ${work_dir}/root-image/boot/vmlinuz* ${work_dir}/iso/${install_dir}/boot/${arch}/kdeosiso
	cp -Lr boot-files/isolinux ${work_dir}/iso/
	cp ${work_dir}/root-image/usr/lib/syslinux/bios/isolinux.bin ${work_dir}/iso/isolinux/
        cp ${work_dir}/root-image/usr/lib/syslinux/bios/isohdpfx.bin ${work_dir}/iso/isolinux/
        cp ${work_dir}/root-image/usr/lib/syslinux/bios/ldlinux.c32 ${work_dir}/iso/isolinux/
        cp ${work_dir}/root-image/usr/lib/syslinux/bios/gfxboot.c32 ${work_dir}/iso/isolinux/
        cp ${work_dir}/root-image/usr/lib/syslinux/bios/whichsys.c32 ${work_dir}/iso/isolinux/
        cp ${work_dir}/root-image/usr/lib/syslinux/bios/mboot.c32 ${work_dir}/iso/isolinux/
        cp ${work_dir}/root-image/usr/lib/syslinux/bios/hdt.c32 ${work_dir}/iso/isolinux/
        cp ${work_dir}/root-image/usr/lib/syslinux/bios/chain.c32 ${work_dir}/iso/isolinux/
        cp ${work_dir}/root-image/usr/lib/syslinux/bios/libcom32.c32 ${work_dir}/iso/isolinux/
        cp ${work_dir}/root-image/usr/lib/syslinux/bios/libmenu.c32 ${work_dir}/iso/isolinux/
        cp ${work_dir}/root-image/usr/lib/syslinux/bios/libutil.c32 ${work_dir}/iso/isolinux/
        cp ${work_dir}/root-image/usr/lib/syslinux/bios/libgpl.c32 ${work_dir}/iso/isolinux/
        mkdir -p ${work_dir}/boot-image
        if [ "`mount -l | grep ${work_dir}/boot-image`" != "" ]; then
           umount -f ${work_dir}/boot-image/proc ${work_dir}/boot-image/sys ${work_dir}/boot-image/dev ${work_dir}/boot-image
        fi
        mount -t aufs -o br=${work_dir}/boot-image:${work_dir}/root-image=ro none ${work_dir}/boot-image
        # for xfs filesystems use instead:
        # mount -t aufs -o br=${work_dir}/boot-image:${work_dir}/root-image=ro,xino=/dev/shm/aufs.xino none ${work_dir}/boot-image
        mount -t proc none ${work_dir}/boot-image/proc
        mount -t sysfs none ${work_dir}/boot-image/sys
        mount -o bind /dev ${work_dir}/boot-image/dev
        cp /usr/lib/initcpio/hooks/kdeos* ${work_dir}/boot-image/usr/lib/initcpio/hooks
        cp /usr/lib/initcpio/install/kdeos* ${work_dir}/boot-image/usr/lib/initcpio/install
        cp mkinitcpio.conf ${work_dir}/boot-image/etc/mkinitcpio.conf
        _kernver=`cat ${work_dir}/boot-image/lib/modules/*/version`
        chroot ${work_dir}/boot-image /usr/bin/mkinitcpio -k ${_kernver} -c /etc/mkinitcpio.conf -g /boot/kdeosiso.img
        mv ${work_dir}/boot-image/boot/kdeosiso.img ${work_dir}/iso/${install_dir}/boot/${arch}/kdeosiso.img
        umount -f ${work_dir}/boot-image/proc ${work_dir}/boot-image/sys ${work_dir}/boot-image/dev ${work_dir}/boot-image
        rm -R ${work_dir}/boot-image
	: > ${work_dir}/build.${FUNCNAME}
	echo -e "$_g >$_W done $_n"
    fi
}

# Prepare /EFI
make_efi() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        echo -e -n "$_r >$_W Prepare ${install_dir}/boot/EFI \n $_n"
        mkdir -p ${work_dir}/iso/EFI/boot
        cp ${work_dir}/root-image/usr/lib/prebootloader/PreLoader.efi ${work_dir}/iso/EFI/boot/bootx64.efi
        cp ${work_dir}/root-image/usr/lib/prebootloader/HashTool.efi ${work_dir}/iso/EFI/boot/

        cp ${work_dir}/root-image/usr/lib/systemd/boot/efi/systemd-bootx64.efi ${work_dir}/iso/EFI/boot/loader.efi

        mkdir -p ${work_dir}/iso/loader/entries
        cp boot-files/loader/loader.conf ${work_dir}/iso/loader/
        cp boot-files/loader/entries/uefi-shell-v2-x86_64.conf ${work_dir}/iso/loader/entries/
        cp boot-files/loader/entries/uefi-shell-v1-x86_64.conf ${work_dir}/iso/loader/entries/

        sed "s|%KDEOSISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g" \
            boot-files/loader/entries/kaos-usb.conf > ${work_dir}/iso/loader/entries/kaos.conf

        sed "s|%KDEOSISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g" \
            boot-files/loader/entries/kaos-nonfree-usb.conf > ${work_dir}/iso/loader/entries/kaos-nonfree.conf

        # EFI Shell 2.0 for UEFI 2.3+ ( http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=UEFI_Shell )
        # moved to https://github.com/tianocore/edk2/tree/master/ShellBinPkg
        curl -o ${work_dir}/iso/EFI/shellx64_v2.efi https://raw.githubusercontent.com/tianocore/edk2/UDK2018/ShellBinPkg/UefiShell/X64/Shell.efi
        # EFI Shell 1.0 for non UEFI 2.3+ ( http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=Efi-shell )
        curl -o ${work_dir}/iso/EFI/shellx64_v1.efi https://raw.githubusercontent.com/tianocore/edk2/UDK2018/EdkShellBinPkg/FullShell/X64/Shell_Full.efi
        : > ${work_dir}/build.${FUNCNAME}
        echo -e "$_g >$_W done $_n"
    fi
}

# Prepare kernel.img::/EFI 
make_efiboot() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        echo -e -n "$_r >$_W Prepare ${install_dir}/iso/EFI \n $_n"
        mkdir -p ${work_dir}/iso/EFI/kiso
        truncate -s 64M ${work_dir}/iso/EFI/kiso/kdeosiso.img
        mkfs.vfat -n KAOS_EFI ${work_dir}/iso/EFI/kiso/kdeosiso.img

        mkdir -p ${work_dir}/efiboot
        mount ${work_dir}/iso/EFI/kiso/kdeosiso.img ${work_dir}/efiboot

        mkdir -p ${work_dir}/efiboot/EFI/kiso
        cp ${work_dir}/iso/${install_dir}/boot/x86_64/kdeosiso ${work_dir}/efiboot/EFI/kiso/kdeosiso.efi
        cp ${work_dir}/iso/${install_dir}/boot/x86_64/kdeosiso.img ${work_dir}/efiboot/EFI/kiso/kdeosiso.img

        mkdir -p ${work_dir}/efiboot/EFI/boot
        cp ${work_dir}/root-image/usr/lib/prebootloader/PreLoader.efi ${work_dir}/efiboot/EFI/boot/bootx64.efi
        cp ${work_dir}/root-image/usr/lib/prebootloader/HashTool.efi ${work_dir}/efiboot/EFI/boot/

        cp ${work_dir}/root-image/usr/lib/systemd//boot/efi/systemd-bootx64.efi ${work_dir}/efiboot/EFI/boot/loader.efi

        mkdir -p ${work_dir}/efiboot/loader/entries
        cp boot-files/loader/loader.conf ${work_dir}/efiboot/loader/
        #cp boot-files/loader/splash.bmp ${work_dir}/efiboot/loader/
        cp boot-files/loader/entries/uefi-shell-v2-x86_64.conf ${work_dir}/efiboot/loader/entries/
        cp boot-files/loader/entries/uefi-shell-v1-x86_64.conf ${work_dir}/efiboot/loader/entries/

        sed "s|%KDEOSISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g" \
            boot-files/loader/entries/kaos-dvd.conf > ${work_dir}/efiboot/loader/entries/kaos.conf

        sed "s|%KDEOSISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g" \
            boot-files/loader/entries/kaos-nonfree-dvd.conf > ${work_dir}/efiboot/loader/entries/kaos-nonfree.conf

        cp ${work_dir}/iso/EFI/shellx64_v2.efi ${work_dir}/efiboot/EFI/
        cp ${work_dir}/iso/EFI/shellx64_v1.efi ${work_dir}/efiboot/EFI/

        umount ${work_dir}/efiboot
        : > ${work_dir}/build.${FUNCNAME}
        echo -e "$_g >$_W done $_n"
    fi
}


# Prepare overlay-image
make_overlay() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        echo -e -n "$_r >$_W Prepare overlay-image \n $_n"
        mkdir -p ${work_dir}/overlay/etc/pacman.d
        cp -Lr overlay ${work_dir}/
        wget -O ${work_dir}/overlay/etc/pacman.d/mirrorlist https://github.com/KaOSx/core/raw/master/pacman-mirrorlist/mirrorlist
        sed -i "s/#Server/Server/g" ${work_dir}/overlay/etc/pacman.d/mirrorlist
        sed -i -e "s/@carch@/${arch}/g" ${work_dir}/overlay/etc/pacman.d/mirrorlist
       
        # locales generation
        cp ${work_dir}/overlay/etc/locale.gen ${work_dir}/root-image/etc
        mkdir -p ${work_dir}/overlay/usr/lib/locale/
        if [ -f "${locale_archive}/locale-archive" ] ; then
	    echo -e -n "$_r >$_W You have specified an existing locale-archive data file, skipping locale-gen \n $_n"
	    cp "${locale_archive}/locale-archive" ${work_dir}/root-image/usr/lib/locale/locale-archive
	    chmod 644 ${work_dir}/root-image/usr/lib/locale/locale-archive
	else
	    echo -e -n "$_r >$_W Generating  locales \n $_n"
	    chroot "${work_dir}/root-image" locale-gen
	    cp ${work_dir}/root-image/etc/locale.gen.bak ${work_dir}/root-image/etc/locale.gen
	fi
        mv ${work_dir}/root-image/usr/lib/locale/locale-archive ${work_dir}/overlay/usr/lib/locale/
        
        chmod -R 755 ${work_dir}/overlay/home
        : > ${work_dir}/build.${FUNCNAME}
        echo -e "$_g >$_W done $_n"
    fi
}

# Prepare overlay-pkgs-image
make_overlay_pkgs() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        echo -e -n "$_r >$_W Prepare overlay-pkgs-image \n $_n"
        overlay-pkgs ${arch} ${work_dir}
        : > ${work_dir}/build.${FUNCNAME}
        echo -e "$_g >$_W done $_n"
    fi
}

# Process isomounts
make_isomounts() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        echo -e -n "$_r >$_W Process isomounts \n $_n"
        sed "s|@ARCH@|${arch}|g" isomounts > ${work_dir}/iso/${install_dir}/isomounts
        : > ${work_dir}/build.${FUNCNAME}
        echo -e "$_g >$_W done $_n"
    fi
}

# Build ISO
make_iso() {
        echo -e -n "$_r >$_W Build ISO \n $_n"
        mkkdeosiso "${verbose}" "${overwrite}" -D "${install_dir}" -L "${iso_label}" -a "${arch}" -c "${compression}" "${high_compression}" iso "${work_dir}" "${name}-${version}-${arch}.iso"
        echo -e "$_g >$_W done $_n"
}

if [[ $verbose == "y" ]]; then
    verbose="-v"
else
    verbose=""
fi

if [[ $overwrite == "y" ]]; then
    overwrite="-f"
else
    overwrite=""
fi

if [[ $high_compression == "y" ]]; then
    high_compression="-x"
else
    high_compression=""
fi

make_root_image
make_boot
make_efi
make_efiboot
make_overlay
make_overlay_pkgs
make_isomounts
make_iso
