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
OPENC_KK_DIR=$BASE_DIR/GEN_EU_P821E10V1.0.0B10_FUS_DL
IN_DIR=$BASE_DIR/put-file-here
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
	(touch $TESTW_FILE 2>/dev/null && rm $TESTW_FILE 2>/dev/null) || (echo "$0 : Merci de donner les droits en écriture au dossier de ce script" && exit)

	# Vérification de l'existence du fichier boot.img
	if [[ ! -f $IN_DIR/boot.img ]]; then
		echo "$0 : Merci de copier le fichier boot.img modifié dans le dossier $IN_DIR" && exit
	fi

	# Re-création de la structure
	rm -rf $TMP_DIR && mkdir $TMP_DIR && mkdir $TMP_DIR/img_system_kk

	# Extraction du zip contenant les fichiers
	unzip $BASE_DIR/openc-system-files.zip -d $TMP_DIR
	
	# Téléchargement et extraction de l'archive contenant les fichiers	
	if [[ ! -d $OPENC_KK_DIR && ! -f $TMP_DIR/openc-kk.zip ]]; then
		(wget -O $TMP_DIR/openc-kk.zip http://down.comebuy.com/GEN_EU_P821E10V1.0.0B10_FUS_DL.zip && unzip $BASE_DIR/openc-kk.zip) || (echo "$0 : Le téléchargement a échoué, merci de réessayer" && exit 1)
	elif [[ ! -d $OPENC_KK_DIR ]]; then
		unzip $BASE_DIR/openc-kk.zip
	fi	
	unzip $BASE_DIR/openc-kk.zip -d $BASE_DIR &&
	# Montage du fichier system.img sur un dossier temporaire
	echo "Afin de monter l'image, il est possible que le mot de passe root vous soit demandé. Il faut en effet les droits root pour exécuter la commande mount"
	(sudo mount $OPENC_KK_DIR/system.img $TMP_DIR/img_system_kk 2>/dev/null
	|| su -c 'mount $TMP_DIR/GEN_EU_P821E10V1.0.0B10_FUS_DL/system.img $TMP_DIR/img_system_kk') &&
	mkdir -p $TMP_DIR/system/vendor/lib &&
	cp -p $TMP_DIR/img_system_kk/vendor/lib/libbt* $TMP_DIR/system/vendor/lib/
	# Démontage du fichier system.img
	
	# Arrêt de Firefox OS
	adb shell stop b2g

	# Envoi de l'image boot sur la mémoire interne du téléphone et application de celle-ci
	adb push $IN_DIR/boot.img /storage/sdcard/boot_bth.img &&
	adb shell dd if=/storage/sdcard/boot_bth.img of=/dev/block/mmcblk0p7 &&
	adb shell rm /storage/sdcard/boot_bth.img

	# Envoi des fichiers sur le téléphone
	adb push $TMP_DIR/system /system &&

	# Attributions des utilisateurs/droits sur les fichiers
	adb shell chmod 644 /system/etc/bluetooth/*
	adb shell chmod 644 /system/lib/libbt-*
	adb shell chmod 644 /system/lib/hw/audio.a2dp.default.so
	adb shell chmod 644 /system/lib/hw/bluetooth.default.so
	adb shell chmod 644 /system/vendor/lib/libbt*.so

	# Finalisation/redémarrage du téléphone
	adb shell sync &&
	adb shell reboot
) ||
echo "$0 : Une erreur est survenue."