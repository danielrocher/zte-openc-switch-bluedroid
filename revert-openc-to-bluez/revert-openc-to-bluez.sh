#! /bin/bash

###################################
# Rétablissement de l'ancienne pile bluetooth (bluez) sur l'Open C
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
UPDATE_BOOTIMG_IN_DIR="$BASE_DIR/../update-bootimage/put-files-here"
OPENC_BASE_DIR="$BASE_DIR/P821A10_FR_ENG_20140806"
IN_DIR="$BASE_DIR/put-files-here"
TMP_DIR="$BASE_DIR/tmp"
TESTW_FILE="$BASE_DIR/testwrite"

if [[ $1 == "-h" ||  $1 == "--help" ]]; then
        echo "Ce script permet d'envoyer les fichiers nécessaires à la prise en charge de bluedroid sur l'Open C" &&
        echo &&
        echo "Utilisation : ${BASH_SOURCE[0]}" &&
        echo "Si vous détenez le pack root fournit par ZTE, merci de le copier dans $IN_DIR et de le renommer packroot.zip" &&
        exit 0
fi

(
	# Vérification des droits en écriture sur le dossier courant
	(touch "$TESTW_FILE" 2>/dev/null && rm "$TESTW_FILE" 2>/dev/null) || (echo "$0 : Merci de donner les droits en écriture au dossier de ce script" && exit 1)

	# Vérification de l'existence du fichier boot.img
	if [[ ! -f "$IN_DIR/boot.img" ]]; then
		cp "$UPDATE_BOOTIMG_IN_DIR/boot.img" "$IN_DIR" || (echo "$0 : Merci de copier le fichier boot.img modifié dans le dossier $IN_DIR" && exit 1)
	fi

	# Vérification de la présence du téléphone
	adb shell getprop >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
			echo "$0 : Merci de connecter l'Open C à cet ordinateur" && exit 1
	fi

	# Re-création de la structure
	echo "$0 : Confirmer l'exécution de la commande -> rm -rvI \"$TMP_DIR\"" &&
	rm -rvI "$TMP_DIR" && mkdir -p "$TMP_DIR/img_system_base"

	# Téléchargement et extraction de l'archive contenant les fichiers
	echo "$0 : Téléchargement et extraction si nécessaire des fichiers du Pack Root pour Open C..."
	if [[ ! -d "$OPENC_BASE_DIR" && ! -f "$IN_DIR/packroot.zip" ]]; then
		(
			wget -nv -O "$IN_DIR/packroot.zip" http://www.ztefrance.com/downloads/Pack_root_du_ZTE_Open_C.zip &&
			unzip "$IN_DIR/packroot.zip" -d "$TMP_DIR" >/dev/null &&
			unzip "$TMP_DIR/Pack root du ZTE Open C/P821A10_FR_ENG_20140806.zip" -d "$BASE_DIR" >/dev/null
		) || (
			echo "$0 : Le téléchargement a échoué, merci de réessayer" &&
			exit 1
		)
	elif [[ ! -d "$OPENC_BASE_DIR" ]]; then
		(unzip "$IN_DIR/packroot.zip" -d "$TMP_DIR" >/dev/null && unzip "$TMP_DIR/Pack root du ZTE Open C/P821A10_FR_ENG_20140806.zip" -d "$BASE_DIR" >/dev/null) ||
		(echo "$0 : Echec de l'extraction du fichier" && exit 1)
	fi

	# Montage du fichier system.img sur un dossier temporaire
	echo "$0 : Montage de l'image system.img sur un dossier temporaire (le mot de passe root peut être requis pour la commande 'mount')..." &&
	(sudo mount "$OPENC_BASE_DIR/system.img" "$TMP_DIR/img_system_base" >/dev/null || su -c "mount $OPENC_BASE_DIR/system.img $TMP_DIR/img_system_base") &&
	mkdir -p "$TMP_DIR/system/etc" &&
	echo "$0 : Rassemblement des fichiers d'origine..." &&
	cp -pR "$TMP_DIR/img_system_base/etc/bluetooth $TMP_DIR/system/etc/" &&
	mkdir -p "$TMP_DIR/system/bin" && cp -p "$TMP_DIR/img_system_base/bin/bluetoothd" "$TMP_DIR/system/bin/" &&
	mkdir -p "$TMP_DIR/system/lib/hw" && cp -p "$TMP_DIR/img_system_base/lib/hw/audio.a2dp.default.so" "$TMP_DIR/system/lib/hw/" &&
	# Démontage du fichier system.img
	echo "$0 : Démontage de l'image system.img (le mot de passe root peut être requis pour la commande 'umount')..." &&
	(sudo umount "$TMP_DIR/img_system_base" || su -c "umount \"$TMP_DIR/img_system_base\"") &&
	
	# Arrêt de Firefox OS et remontage de la partition system
	adb shell stop b2g &&
	adb remount >/dev/null &&
	
	# Suppression des fichiers inutiles
	echo "$0 : Suppression des fichiers liés à bluedroid du téléphone..." &&
	adb shell rm /system/bin/bluetoothd &&
	adb shell rm /system/etc/bluetooth/* &&
	adb shell rm /system/lib/libbt-* &&
	adb shell rm /system/lib/hw/audio.a2dp.default.so &&
	adb shell rm /system/lib/hw/bluetooth.default.so &&
	adb shell rm /system/vendor/lib/libbt*.so &&

	# Envoi de l'image boot sur la mémoire interne du téléphone et application de celle-ci
	echo "$0 : Envoi des fichiers sur le téléphone..." &&
	adb push "$IN_DIR/boot.img" /storage/sdcard/boot_bluez.img >/dev/null &&
	adb shell dd if=/storage/sdcard/boot_bluez.img of=/dev/block/mmcblk0p7 >/dev/null &&
	adb shell rm /storage/sdcard/boot_bluez.img
	# Envoi des fichiers sur le téléphone
	adb push "$TMP_DIR/system" /system >/dev/null 2>&1 &&

	# Attributions des utilisateurs/droits sur les fichiers
	echo "$0 : Restauration des permissions sur les fichiers..." &&
	adb shell chown root:shell /system/bin/bluetoothd &&
	adb shell chmod 755 /system/bin/bluetoothd &&
	adb shell chmod 644 /system/etc/bluetooth/* &&
	adb shell chmod 644 /system/lib/hw/audio.a2dp.default.so &&

	# Finalisation/redémarrage du téléphone
	echo "$0 : Redémarrage du téléphone..." &&
	adb shell sync &&
	adb shell reboot
) ||
echo "$0 : Une erreur est survenue."