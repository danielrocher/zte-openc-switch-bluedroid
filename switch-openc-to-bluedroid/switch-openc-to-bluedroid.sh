#! /bin/bash

###################################
# Passage pile bluetooth Open C à bluedroid
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
BASE_DIR=`dirname $(readlink -f $0)`
OPENC_KK_DIR=$BASE_DIR/GEN_EU_P821E10V1.0.0B10_FUS_DL
IN_DIR=$BASE_DIR/put-files-here
TMP_DIR=$BASE_DIR/tmp
TESTW_FILE=$BASE_DIR/testwrite

if [[ $1 == "-h" ||  $1 == "--help" ]]; then
        echo "Ce script permet d'envoyer les fichiers nécessaires à la prise en charge de bluedroid sur l'Open C" &&
        echo &&
        echo "Utilisation : ${BASH_SOURCE[0]}" &&
        echo "Le fichier boot.img doit être placé dans $IN_DIR" &&
        exit 0
fi

(
	# Vérification des droits en écriture sur le dossier courant
	(touch $TESTW_FILE 2>/dev/null && rm $TESTW_FILE 2>/dev/null) || (echo "$0 : Merci de donner les droits en écriture au dossier de ce script" && exit 1)

	# Vérification de l'existence du fichier boot.img
	if [[ ! -f $IN_DIR/boot.img ]]; then
		echo "$0 : Merci de copier le fichier boot.img modifié dans le dossier $IN_DIR" && exit 1
	fi

	# Vérification de la présence du téléphone
	adb shell getprop >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
			echo "$0 : Merci de connecter l'Open C à cet ordinateur" && exit 1
	fi

	# Re-création de la structure
	rm -rf $TMP_DIR && mkdir -p $TMP_DIR/img_system_kk

	# Extraction du zip contenant les fichiers
	echo "$0 : Extraction de l'archive contenant les premiers fichiers pour bluedroid..." &&
	unzip $BASE_DIR/openc-system-files.zip -d $TMP_DIR >/dev/null &&

	# Téléchargement et extraction de l'archive contenant les fichiers
	echo "$0 : Téléchargement et extraction si nécessaire de l'archive Kitkat pour Open C..."
	if [[ ! -d $OPENC_KK_DIR && ! -f $TMP_DIR/openc-kk.zip ]]; then
		(wget -O $TMP_DIR/openc-kk.zip http://down.comebuy.com/GEN_EU_P821E10V1.0.0B10_FUS_DL.zip && unzip $TMP_DIR/openc-kk.zip -d $BASE_DIR) || (echo "$0 : Le téléchargement a échoué, merci de réessayer" && exit 1)
	elif [[ ! -d $OPENC_KK_DIR ]]; then
		unzip $TMP_DIR/openc-kk.zip -d $BASE_DIR  >/dev/null || (echo "$0 : Echec de l'extraction du fichier" && exit 1)
	fi

	# Montage du fichier system.img sur un dossier temporaire
	echo "$0 : Montage de l'image system.img sur un dossier temporaire (le mot de passe root peut être requis pour la commande 'mount')..." &&
	(sudo mount $OPENC_KK_DIR/system.img $TMP_DIR/img_system_kk >/dev/null || su -c "mount $OPENC_KK_DIR/system.img $TMP_DIR/img_system_kk") &&
	mkdir -p $TMP_DIR/system/vendor/lib &&
	echo "$0 : Récupération des blobs..." &&
	cp -p $TMP_DIR/img_system_kk/vendor/lib/libbt* $TMP_DIR/system/vendor/lib/ &&
	# Démontage du fichier system.img
	echo "$0 : Démontage de l'image system.img (le mot de passe root peut être requis pour la commande 'umount')..." &&
	(sudo umount $TMP_DIR/img_system_kk || su -c "umount $TMP_DIR/img_system_kk") &&
	
	# Arrêt de Firefox OS et remontage de la partition system
	adb shell stop b2g &&
	adb remount >/dev/null &&

	# Envoi de l'image boot sur la mémoire interne du téléphone et application de celle-ci
	echo "$0 : Envoi des fichiers sur le téléphone..." &&
	adb push $IN_DIR/boot.img /storage/sdcard/boot_bth.img >/dev/null &&
	adb shell dd if=/storage/sdcard/boot_bth.img of=/dev/block/mmcblk0p7 >/dev/null &&
	adb shell rm /storage/sdcard/boot_bth.img

	# Envoi des fichiers sur le téléphone
	adb push $TMP_DIR/system /system >/dev/null 2>&1 &&

	# Attributions des utilisateurs/droits sur les fichiers
	echo "$0 : Attribution des permissions sur les fichiers..." &&
	adb shell chmod 644 /system/etc/bluetooth/* &&
	adb shell chmod 644 /system/lib/libbt-* &&
	adb shell chmod 644 /system/lib/hw/audio.a2dp.default.so &&
	adb shell chmod 644 /system/lib/hw/bluetooth.default.so &&
	adb shell chmod 644 /system/vendor/lib/libbt*.so &&

	# Finalisation/redémarrage du téléphone
	echo "$0 : Redémarrage du téléphone..." &&
	adb shell sync &&
	adb shell reboot
) ||
echo "$0 : Une erreur est survenue."