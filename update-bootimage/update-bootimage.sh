#! /bin/bash

###################################
# Préparation boot.img pour Open C
# Copyright (C) 2016 micgeri (https://github.com/micgeri)
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
MKBOOT_DIR="$BASE_DIR/mkbootimg_tools-bootimg-openc-ok"
IN_DIR="$BASE_DIR/put-files-here"
TMP_DIR="$BASE_DIR/tmp"
TESTW_FILE="$BASE_DIR/testwrite"
OUT_DIR="$BASE_DIR/out"
OUT_FILE=boot.img
OUT_FOR_SWITCH_DIR="$BASE_DIR/../switch-openc-to-bluedroid/put-files-here"

if [[ $1 == "-h" ||  $1 == "--help" ]]; then
        echo "Ce script permet de modifier l'image boot du ZTE Open C, afin de prendre en charge bluedroid" &&
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
		echo "$0 : Merci de copier le fichier boot.img du pack root dans le dossier $IN_DIR" && exit
	fi

	# Re-création de la structure
	if [[ -d "$TMP_DIR" ]]; then
		echo "$0 : Confirmer l'exécution de la commande -> rm -rvI \"$TMP_DIR\"" &&
		rm -rvI "$TMP_DIR"
	fi
	mkdir -p "$TMP_DIR"
	if [[ -d "$OUT_DIR" ]]; then
		echo "$0 : Confirmer l'exécution de la commande -> rm -rvI \"$OUT_DIR\"" &&
		rm -rvI "$OUT_DIR"
	fi
	mkdir -p "$OUT_DIR"

	# Récupération de l'utilitaire mkboot, si nécessaire
	if [[ ! -d "$MKBOOT_DIR" && ! -f "$IN_DIR/mkboot.zip" ]]; then
		echo "$0 : Téléchargement et extraction des outils mkboot..." &&
		(wget -nv -O "$IN_DIR/mkboot.zip" https://github.com/micgeri/mkbootimg_tools/archive/bootimg-openc-ok.zip && unzip "$IN_DIR/mkboot.zip" -d "$BASE_DIR" >/dev/null) || { echo "$0 : Impossible de télécharger l'utilitaire mkboot" && exit 1; }
	elif [[ ! -d "$MKBOOT_DIR" ]]; then
		echo "$0 : Extraction des outils mkboot..." &&
		unzip "$IN_DIR/mkboot.zip" -d "$BASE_DIR" >/dev/null
	fi

	# Préparation de l'image de boot
	# Extraction
	echo "$0 : Extraction de l'image de boot original..." &&
	"$MKBOOT_DIR/mkboot" "$IN_DIR/boot.img" "$TMP_DIR/boot" &&
	echo "$0 : Ajout des éléments pour la nouvelle image..." &&
	# Modification du fichier init.rc
	patch -s "$TMP_DIR/boot/ramdisk/init.rc" "$BASE_DIR/prepare-bootimage-for-bluedroid.patch" &&
	# Copie du fichier init.bluetooth.rc dans le dossier
	cp -p "$BASE_DIR/init.bluetooth.rc" "$TMP_DIR/boot/ramdisk/" &&
	# Compilation de la nouvelle image
	echo "$0 : Création de la nouvelle image de boot..." &&
	"$MKBOOT_DIR/mkboot" "$TMP_DIR/boot" "$OUT_DIR/$OUT_FILE" &&
	echo "$0 : Le fichier $OUT_FILE a été généré avec succès dans $OUT_DIR !"

	# Proposition de copier le fichier généré pour l'envoi des éléments vers le téléphone
	echo "---" &&
	read -p "Voulez-vous copier le fichier généré pour l'exécution du script switch-openc-to-bluedroid.sh [O/n] ? (n par défaut) " rep
	if [[ $rep == "O" || $rep == "o" ]]; then
		mkdir -p "$OUT_FOR_SWITCH_DIR" &&
		cp "$OUT_DIR/$OUT_FILE" "$OUT_FOR_SWITCH_DIR/" &&
		echo "$0  : Le fichier $OUT_FILE a été copié dans $OUT_FOR_SWITCH_DIR/ avec succès !"
	fi
) ||
echo "$0 : Une erreur est survenue."