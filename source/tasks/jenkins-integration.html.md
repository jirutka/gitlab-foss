---
title: Integrace GitLab s Jenkins CI
---

Integrace GitLab s Jenkins CI
=============================

Současný stav
-------------

GitLab zatím nemá explicitní podporu pro Jenkins CI a vice versa. Oba však poskytují RESTful JSON API (viz [GitLab](https://github.com/gitlabhq/gitlabhq/tree/master/doc/api) a [Jenkins](https://wiki.jenkins-ci.org/display/JENKINS/Remote+access+API)), která lze pro toto využít. GitLab navíc nabízí tzv. [_web hooks_](https://gitlab.fit.cvut.cz/help/web_hooks) a Jenkins CI bohatou podporu [rozšíření](https://wiki.jenkins-ci.org/display/JENKINS/Plugins).


Problém
-------

Když chce uživatel napojit svůj GitLab repozitář na Jenkins, musí nejprve na Jenkins ručně vytvořit projekt, zadat adresu repozitáře, nastavit práva uživatelům atd. Jelikož repozitáře nejsou veřejně přístupné, tak navíc musí do GitLab přidat _deploy key_ (SSH klíč) z Jenkins, který je ale pro všechny projekty na Jenkins společný! Výsledek testů se poté dozví opět jen na Jenkins.


Požadavek
---------

Navrhněte a po schválení implementujte modul (přesněji [Rails Engine](http://guides.rubyonrails.org/engines.html), příp. samostatnou komponentu) pro komplexní integraci GitLab s Jenkins CI. Inspirujte se řešením na GitHub pro Travis CI.

* Parametry pro Jenkins bude možné nastavit přes konfigurační soubor v repozitáři (inspirace z [Travis CI](http://about.travis-ci.org/docs/user/build-configuration/)).
* Modul bude automaticky detekovat konfigurační soubor v repozitáři, potom:
   + Automaticky vytvoří projekt na Jenkins a nastaví základní parametry.
   + Nastaví uživatelská práva k Jenkins projektu pro všechny členy GitLab projektu, podle jejich rolí.
   + Vygeneruje SSH klíč, který Jenkins použije pro přístup do repozitáře, ve kterém se přidá jako _deploy key_.
* Při testování _merge requests_ Jenkins do GitLabu automaticky vloží komentář informující o výsledku (inspirace z GitHub + Travis).


Poznámky
--------

Vývojáři GitLabu tuto funkcionalitu plánují zařadit ve verzi 3.0 a aktuálně [přijímají _pull requests_](https://github.com/gitlabhq/gitlabhq/issues/1432) s návrhy nebo přímo implementací.

Uvedené požadavky jsou spíše orientační, tento úkol je **nutné** předem konzultovat se zadavatelem a domluvit se na konkrétním způsobu řešení!
