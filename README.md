# zte-openc-switch-bluedroid
Scripts permettant de passer le ZTE Open C en bluedroid.  
*Testés sur Debian Wheezy (7.X) et Debian Jessie (8.X)*  
**ATTENTION : Merci de placer ces scripts dans un dossier ne contenant pas d'espace (pas de /home/utilisateur/mon dossier/zte-openc-switch-bluedroid par exemple)**  

Liste des scripts :
- update-bootimage/update-bootimage.sh : Permet de modifier l'image de boot, afin de gérer les changements au niveau du bluetooth.  
- switch-openc-to-bluedroid/switch-openc-to-bluedroid.sh : Permet d'envoyer l'image de boot modifié, et les autres fichiers nécessaires, sur le ZTE Open C.  
- revert-openc-to-bluez/revert-openc-to-bluez.sh : Permet de restaurer la pile bluetooth d'origine.  

Prérequis:
- ZTE Open C déjà rooté.
- fichier boot.img de l'Open C : Il est récupérable au sein du pack root de ZTE, ou dans le dossier zte-openc-add-timekeep-at-boot/ (fichier boot_timekeep.img) si vous avez exécuté ce dernier.
- Linux installé et configuré, voir [ce lien](https://developer.mozilla.org/fr/Firefox_OS/Prerequis_pour_construire_Firefox_OS#Pour_Linux_.3A_configurer_la_r.C3.A8gle_udev_li.C3.A9e_au_t.C3.A9l.C3.A9phone)
- ADB installé, voir [ce lien](https://developer.mozilla.org/fr/Firefox_OS/D%C3%A9boguer/Installer_ADB)

**Procédure mise à jour boot.img**  
1. Se positionner dans le dossier 'update-bootimage'.  
2. Copier le boot.img du pack root ZTE dans le dossier 'put-files-here'.  
3. Exécuter update-bootimage.sh, pour obtenir l'image de boot modifié.  
4. Si la procédure suivante est nécessaire, répondre "o" (sans les guillemets) à la question posée par le script.  
**Procédure envoi fichier vers téléphone**  
1. Se positionner dans le dossier 'switch-openc-to-bluedroid'.  
2. *Facultatif si point 4 précédent effectué : Copier l'image généré par update-bootimage.sh (update-bootimage/out/boot.img) dans le dossier 'put-files-here'.*    
3. Connecter l'Open C à l'ordinateur exécutant le script.  
4. Exécuter switch-openc-to-bluedroid.sh, et le laisser travailler jusqu'au redémarrage du téléphone.  
**Procédure restauration pile bluetooth origine**  
1. Se positionner dans le dossier 'revert-openc-to-bluez'.  
2. Si détention du ZIP du pack root, le copier dans le dossier 'put-files-here', puis renommer cette copie 'packroot.zip' (sans les quotes).  
3. Connecter l'Open C à l'ordinateur exécutant le script.  
4. Exécuter revert-openc-to-bluez.sh, et le laisser travailler jusqu'au redémarrage du téléphone.  


Pour plus d'informations sur les raisons de ces manipulations pour l'Open C, les anglophones pourront se rendre sur le bug 1213591 de [Bugzilla@Mozilla](https://bugzilla.mozilla.org/show_bug.cgi?id=1213591)

-------------------------------------------------------

REMARQUE :

La décompilation et la recompilation du fichier boot.img sont effectués à l'aide d'outils tiers : mkbootimg_tools. Un fork de ces outils a été effectué afin de garder la compatibilité avec le boot.img de l'Open C.  
Ces outils sont disponibles dans leurs dernières versions à cette adresse : https://github.com/xiaolu/mkbootimg_tools  


AUTRE REMARQUE :

Ce script a été écrit pour le boot.img d'origine (tel que fournit par ZTE). Il est donc possible qu'il ne fonctionne pas si l'image a été modifié. Dans ce cas, il faudra effectuer les manipulations manuellement.
