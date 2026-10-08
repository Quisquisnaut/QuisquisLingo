QuisquisLingo - Guide pour Windows
=================================

QuisquisLingo est une application d'apprentissage des langues destinée aux
apprenants et aux créateurs de cours. Elle réunit des leçons structurées, des
exercices interactifs, des activités audio et des outils de révision, tout en
offrant des fonctions pour créer et modifier des cours de langue.

Elle s'adresse aussi bien aux personnes souhaitant étudier une langue qu'aux
auteurs, enseignants et autres utilisateurs désirant créer leurs propres cours.

Pour découvrir rapidement et visuellement le fonctionnement de QuisquisLingo,
consultez QQL infographic.png, incluse dans le package de l'application.

Pour démarrer QuisquisLingo, exécutez QuisquisLingo.exe.

UTILISATION DU PACKAGE
----------------------

Ce package contient l'application QQL. Extrayez l'intégralité de l'archive ZIP
avant de la démarrer et conservez ensemble tous les fichiers fournis et le
dossier data. Ne distribuez, déplacez, supprimez ou renommez pas séparément des
fichiers EXE ou DLL.

VÉRIFICATIONS AU DÉMARRAGE
--------------------------

Avant le démarrage, QuisquisLingo vérifie les fichiers requis du package, la
compatibilité Windows et Media Foundation. Ces vérifications ne téléchargent
et n'installent aucun logiciel, ne demandent pas d'élévation de privilèges, ne
modifient pas le registre et ne changent pas Windows.

Un problème récupérable produit un message unique avec Continue anyway et
Cancel. Continue anyway tente de démarrer QQL ; Cancel le ferme. Si un fichier
essentiel manque, le message propose Close, car le package doit être téléchargé
et extrait de nouveau.

La prise en charge de Wine est expérimentale. L'absence de Media Foundation
sous Wine peut empêcher le démarrage ou le fonctionnement de l'audio et des
fonctions multimédias.

RUNTIME MICROSOFT VISUAL C++
----------------------------

Le package complet comprend les fichiers runtime Microsoft Visual C++ x64
suivants :

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Si l'un d'eux manque, téléchargez à nouveau le package Windows complet de
QuisquisLingo et extrayez-le entièrement. Utilisez uniquement les sources
officielles de Microsoft pour les installateurs runtime et ne téléchargez
jamais de DLL individuelles depuis des sites tiers.

Informations officielles de Microsoft :
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Les éditions Windows N peuvent nécessiter Microsoft Media Feature Pack pour les
fonctions audio et multimédias. Media Feature Pack est normalement disponible
dans les Fonctionnalités facultatives de Windows. Sur certaines versions de
Windows N, il peut ne pas y être disponible. Dans ce cas, téléchargez sur le
site web de Microsoft le Media Feature Pack adapté à votre version de Windows.

Redémarrez Windows après avoir installé Media Feature Pack. QuisquisLingo ne le
télécharge ni ne l'installe automatiquement et ne modifie pas les paramètres
du système.

SYNTHÈSE VOCALE
---------------

QuisquisLingo utilise les voix installées dans Windows. Les langues et voix
disponibles dépendent des composants linguistiques et vocaux installés sur
l'ordinateur. Si aucune voix compatible n'est disponible, installez le
composant approprié depuis les paramètres Windows.

Audio Settings > Test Voice lit uniquement le texte saisi et utilise la langue
vocale configurée par le cours sélectionné.

JOURNAUX ET DIAGNOSTIC
----------------------

Le journal principal des incidents est enregistré ici :

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Le journal de vérification du démarrage est enregistré ici :

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug affiche les options de diagnostic. Les journaux restent sur
l'ordinateur local et ne sont pas téléversés automatiquement.

DÉPANNAGE
---------

1. Extrayez entièrement l'archive ZIP complète.
2. Exécutez QuisquisLingo.exe depuis le package extrait.
3. Si une DLL runtime est signalée comme manquante, téléchargez et extrayez à
   nouveau le package complet avant d'envisager un installateur officiel de
   Microsoft.
4. Si Media Feature Pack est requis, suivez les indications ci-dessus et
   redémarrez Windows après son installation.
5. Si QQL ne démarre toujours pas, conservez le message d'erreur complet et les
   fichiers journaux disponibles pour l'assistance.
