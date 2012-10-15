---
title: Integrace Gollum wiki do GitLab
---

Integrace Gollum wiki do GitLab
===============================

Současný stav
-------------

GitLab poskytuje projektům jednoduchou wiki s podporou verzování stránek, syntaxí [Markdown](http://daringfireball.net/projects/markdown/) a lineární diskuzí (komentování). Využívá vlastní implementaci, obsah stránek ukládá do relační databáze.


Problém
-------

Wiki stránky, které vývojáři často využívají pro dokumentaci, jsou oddělené od vlastního repozitáře. Není možné je snadno přenášet společně s kódem uloženým v repozitáři. Lze s nimi pracovat pouze prostřednictvím GitLabu, nikoli přímo přes Git a editovat v libovolném textovém editoru, jak to umožňuje např. [GitHub](https://github.com/blog/699-making-github-more-open-git-backed-wikis).


Požadavek
---------

Navrhněte a po schválení implementujte modul (přesněji [Rails Engine](http://guides.rubyonrails.org/engines.html)) pro integraci wiki systému [Gollum](https://github.com/github/gollum) do GitLab (pro správu Git repozitářů využívá [Gitolite](https://github.com/sitaramc/gitolite)). Nabízí se v zásadě dva způsoby řešení:

* Gollum nahradí stávající wiki tak, že nedojde ke změně na _front-end_, pouze se stránky místo do databáze budou ukládat do Git repozitáře.
* Stávající wiki bude ponechána beze změny a modul nabídne kompletní alternativu. V nastavení projektu pak bude možné zvolit původní wiki, nebo tuto novou.

Obě řešení mají své výhody a nevýhody, je nutné je zvážit, zejména s ohledem na míru invazivnosti zásahu do jádra aplikace, a zvolit nejvhodnější řešení.
