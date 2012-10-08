---
title: Výkonnostní analýza a optimalizace GitLab
---

Výkonnostní analýza a optimalizace GitLab
=========================================

Současný stav
-------------

GitLab využívá SQL databázi, _key-value_ úložiště [Redis](http://redis.io) pro [Resque](https://github.com/defunkt/resque) a [Gitolite](https://github.com/sitaramc/gitolite) pro správu repozitářů.

Nad SQL databází používá ORM abstrakci ActiveRecord z Ruby on Rails. Oficiálně podporuje MySQL a SQLite databázi, ale s úpravami v [našem _forku_](https://github.com/cvut/gitlabhq/tree/postgres) funguje i nad PostgreSQL.

Aktuálně nepoužívá žádné sofistikovanější cachování.


Problém
-------

Uživatelé GitLab pociťují potíže s dlouhou odezvou aplikace. Problém se týká zejm. stránek s výpisem událostí (tj. `dashboard/index`, `projects/show`) a stromem souborů v repozitáři, jejichž zpracování trvá příliš dlouho.  Zdá se, že úzké hrdlo je na persistentní vrstvě, konkr. neoptimální dotazy do databáze.


Požadavek
---------

1. Proveďte výkonnostní analýzu _(performance profiling)_ a identifikujte úzká hrdla aplikace ([viz RailsGuides](http://guides.rubyonrails.org/performance_testing.html)).
2. Nastudujte si podporu cachování v Ruby on Rails aplikacích.
3. Navrhněte optimalizační úpravy a předejte je cvičícímu.
4. Po schválení dané úpravy implementujte.


Poznámky
--------

* Pokud by načítání událostí _(events)_ nebylo možné uspokojivě optimalizovat pro relační databázi, zvažte jejich cachování přes Redis.
* Řešení musí korektně fungovat s PostgreSQL a MySQL!
