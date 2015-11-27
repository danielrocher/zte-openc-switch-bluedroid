# zte-openc-switch-bluedroid
Scripts permettant de passer le ZTE Open C en bluedroid.

update-bootimage/update-bootimage.sh : Permet de modifier l'image de boot, afin de gérer les changements au niveau du bluetooth.
switch-openc-to-bluedroid/switch-openc-to-bluedroid.sh : Permet d'envoyer l'image de boot modifié, et les autres fichiers nécessaires, sur le ZTE Open C.

Prérequis:
	- fichier boot.img de l'Open C : Il est récupérable au sein du pack root de ZTE.

Pour plus d'informations sur les raisons de ces manipulations pour l'Open C, les anglophones pourront se rendre sur le bug 1213591 de Bugzilla@Mozilla : https://bugzilla.mozilla.org/show_bug.cgi?id=1213591

-------------------------------------------------------

REMARQUE :

La décompilation et la recompilation du fichier boot.img sont effectués à l'aide d'outils tiers : mkbootimg_tools.
Ces outils sont disponibles à cette adresse : https://github.com/xiaolu/mkbootimg_tools