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
BASE_DIR=`dirname "$(readlink -f $0)"`
OPENC_KK_DIR="$BASE_DIR/P821E10_KITKAT"
IN_DIR="$BASE_DIR/put-files-here"
TMP_DIR="$BASE_DIR/tmp"
TESTW_FILE="$BASE_DIR/testwrite"

if [[ $1 == "-h" ||  $1 == "--help" ]]; then
        echo "Ce script permet d'envoyer les fichiers nécessaires à la prise en charge de bluedroid sur l'Open C" &&
		echo "ATTENTION ! B2G SERA ARRETE AU COURS DES OPERATIONS ET LE TELEPHONE REDEMARRERA."
        echo &&
        echo "Utilisation : ${BASH_SOURCE[0]}" &&
        echo "Le fichier boot.img doit être placé dans $IN_DIR" &&
        exit 0
fi

(
	# Vérification des droits en écriture sur le dossier courant
	(touch "$TESTW_FILE" 2>/dev/null && rm "$TESTW_FILE" 2>/dev/null) || { echo "$0 : Merci de donner les droits en écriture au dossier de ce script" && exit; }

	# Vérification de l'existence du fichier boot.img
	if [[ ! -f "$IN_DIR/boot.img" ]]; then
		echo "$0 : Merci de copier le fichier boot.img modifié dans le dossier $IN_DIR" && exit 1
	fi

	# Vérification de la présence du téléphone
	adb shell getprop >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
			echo "$0 : Merci de connecter l'Open C à cet ordinateur" && exit 1
	fi

	# Re-création de la structure
	if [[ -d "$TMP_DIR" ]]; then
		echo "$0 : Confirmer l'exécution de la commande -> rm -rvI \"$TMP_DIR\"" &&
		rm -rvI "$TMP_DIR"
	fi
	mkdir -p "$TMP_DIR"

	# Extraction du zip contenant les fichiers
	echo "$0 : Extraction de l'archive contenant les premiers fichiers pour bluedroid..." &&
	unzip "$BASE_DIR/openc-system-files.zip" -d "$TMP_DIR" >/dev/null &&

	# Téléchargement et extraction de l'archive contenant les fichiers
	if [[ ! -d "$OPENC_KK_DIR" && ! -f "$IN_DIR/kk.zip" ]]; then
		(
			echo "$0 : Téléchargement et extraction de l'archive Kitkat pour Open C..." &&
			wget -nv -O "$IN_DIR/kk.zip" http://download.ztedevice.com/UpLoadFiles/product/643/4880/soft/2014101309394339.zip &&
			unzip "$IN_DIR/kk.zip" -d "$TMP_DIR" >/dev/null &&
			find "$TMP_DIR/" -name update.zip -exec unzip {} -d "$OPENC_KK_DIR" \;
		) || { echo "$0 : Le téléchargement a échoué, merci de réessayer" && exit 1; }
	elif [[ ! -d "$OPENC_KK_DIR" ]]; then
		(
			echo "$0 : Extraction de l'archive Kitkat pour Open C..." &&
			unzip "$IN_DIR/kk.zip" -d "$TMP_DIR" >/dev/null &&
			find "$TMP_DIR/" -name update.zip -exec unzip {} -d "$OPENC_KK_DIR" \;
		) || { echo "$0 : Echec de l'extraction du fichier" && exit 1; }
	fi

	echo "$0 : Récupération des blobs..." &&
	mkdir -p "$TMP_DIR/system/vendor/lib" &&
	cp -p "$OPENC_KK_DIR"/system/vendor/lib/libbt* "$TMP_DIR/system/vendor/lib/" &&
	
	# Arrêt de Firefox OS et remontage de la partition system
	adb shell stop b2g &&
	adb remount >/dev/null &&

	# Envoi de l'image boot sur la mémoire interne du téléphone et application de celle-ci
	echo "$0 : Envoi des fichiers sur le téléphone..." &&
	adb push "$IN_DIR/boot.img" /storage/sdcard/boot_bth.img >/dev/null &&
	adb shell dd if=/storage/sdcard/boot_bth.img of=/dev/block/mmcblk0p7 >/dev/null &&
	adb shell rm /storage/sdcard/boot_bth.img

	# Envoi des fichiers sur le téléphone
	adb push "$TMP_DIR/system" /system >/dev/null 2>&1 &&

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