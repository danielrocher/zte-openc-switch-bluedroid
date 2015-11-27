#! /bin/bash

###################################
# Préparation boot.img pour Open C
# Copyright (C) 2015 Micgeri
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
###################################


### Variables ###
BASE_DIR=`pwd`
MKBOOT_DIR=$BASE_DIR/mkbootimg_tools-master
IN_DIR=$BASE_DIR/put-files-here
TMP_DIR=$BASE_DIR/tmp
TESTW_FILE=$BASE_DIR/testwrite
OUT_DIR=$BASE_DIR/out
OUT_FILE=boot_bluetooth.img

if [[ $1 == "-h" ||  $1 == "--help" ]]; then
        echo "Ce script permet de modifier l'image boot du ZTE Open C, afin de prendre en charge bluedroid" &&
        echo &&
        echo "Utilisation : ${BASH_SOURCE[0]}" &&
        echo "Le fichier boot.img doit être placé dans $IN_DIR" &&
        exit 0
fi

(
	# Vérification des droits en écriture sur le dossier courant
	(touch $TESTW_FILE 2>/dev/null && rm $TESTW_FILE 2>/dev/null) || (echo "$0 : Merci de donner les droits en écriture au dossier de ce script" && exit)

	# Vérification de l'existence du fichier boot.img
	if [[ ! -f $IN_DIR/boot.img ]]; then
		echo "$0 : Merci de copier le fichier boot.img du pack root dans le dossier $IN_DIR" && exit
	fi

	# Re-création de la structure
	rm -rf $TMP_DIR && mkdir $TMP_DIR &&
	rm -rf $OUT_DIR && mkdir $OUT_DIR

	# Récupération de l'utilitaire mkboot, si nécessaire
	if [[ ! -d $MKBOOT_DIR && ! -f $TMP_DIR/mkboot.zip ]]; then
		(wget -O $TMP_DIR/mkboot.zip https://github.com/xiaolu/mkbootimg_tools/archive/master.zip && unzip $TMP_DIR/mkboot.zip) || (echo "$0 : Impossible de télécharger l'utilitaire mkboot" && exit 1)
	elif [[ ! -d $MKBOOT_DIR ]]; then
		unzip $TMP_DIR/mkboot.zip
	fi

	# Préparation de l'image de boot
	# Extraction
	$MKBOOT_DIR/mkboot $IN_DIR/boot.img $TMP_DIR/boot &&
	# Modification du fichier init.rc
	cd $TMP_DIR &&
	patch -p1 < $BASE_DIR/prepare-bootimage-for-bluedroid.patch &&
	cd - &&
	# Copie du fichier init.bluetooth.rc dans le dossier
	cp -p $BASE_DIR/init.bluetooth.rc $TMP_DIR/boot/ramdisk/ &&
	# Compilation de la nouvelle image
	$MKBOOT_DIR/mkboot $TMP_DIR/boot $OUT_DIR/$OUT_FILE &&

	echo "$0 : Le fichier $OUT_FILE a été généré avec succès dans $OUT_DIR !"
) ||
echo "$0 : Une erreur est survenue."