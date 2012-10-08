---
title: Integrace GitLab s LDAP
---

Integrace GitLab s LDAP
=======================

Současný stav
-------------

GitLab pro autentizaci uživatelů z externích zdrojů využívá knihovnu [OmniAuth](https://github.com/intridea/omniauth), která mj. poskytuje i autentizaci proti LDAP. Současné řešení funguje tak, že záznam uživatele se v databázi GitLab vytvoří až v momentě, kdy se uživatel prostřednictvím LDAP poprvé přihlásí.


Problém
-------

Do projektu nelze přidat uživatele (člena), který ještě nemá vytvořený účet, tj. záznam v lokální databázi. To znamená, že se nejprve musí alespoň jednou přihlásit do GitLab, aby ho bylo možné přidat jako člena projektu.


Požadavek
---------

Upravte přidávání členů týmu (stránka `team_members/new`) následujícím způsobem.

* Našeptávač uživatelů bude vedle lokální databáze prohledávat i LDAP (podle loginu, příjmení a jména).
* V okně našeptávače se u LDAP uživatelů vedle jména a příjmení zobrazí i login (v závorce a šedým písmem).
* Po přidání do projektu uživatele z LDAP, který ještě nemá GitLab účet, dojde automaticky k jeho vytvoření (a zaslání info mailu).
   + Toto chování bude možné změnit v konfiguračním souboru `conf/gitlab.yml`.
* Otestujte odezvu rozhraní a chování aplikace v případě výpadku LDAP serveru.
