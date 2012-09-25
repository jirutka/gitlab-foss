---
title: Role a práva
---

# Role a práva

## Host (Guest)

Host vidí základní informace o projektu, přehled oznámení, přílohy, útržky kódu _(snippets)_, úkoly _(issues)_, žádosti o začlenění _(merge requests)_, stěnu a wiki. Může vytvářet nové úkoly, psát komentáře a zanechávat zprávy na zdi.

Co je podstatné, **nemá žádný přístup ke kódu.** Tato role se tedy hodí nejvýše pro prosté uživatele, nikoli (potenciální) spolupracovníky.


## Reportér (Reporter)

Reportér získává navíc přístup do repozitáře pro čtení (přes web i git), může si projekt stáhnout v TAR archivu a přidávat útržky _(snippets)_. Tuto roli získají všichni přihlášení uživatelé, když projekt nastavíte jako „veřejný“.


## Vývojář (Developer)

Vývojář už získává přístup do repozitáře i pro zápis. Může přispívat _(git push)_ do nechráněných větví, rovněž je rušit a zakládat nové. Dále má právo přidávat štítky _(git tags)_ a psát na wiki stránky.


## Správce (Master)

Správce může přidávat nové členy projektu (vč. přiřazení rolí), měnit nastavení a informace o projektu, konfigurovat háčky _(hooks)_ a přidávat SSH klíče s právem ke čtení repozitáře _(deploy key)_. Dále má právo přispívat do chráněných větví, rovněž je odstraňovat i nastavovat a také používat _sílu_ _(git --force)._ :)
