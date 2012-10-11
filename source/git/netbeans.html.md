---
title: Git v NetBeans
---

Git v NetBeans
==============

NetBeans mají velmi špatnou podporu Gitu, uživatelské rozhraní je neintuitivní a nabízí jen zlomek z toho, co Git umí. Doporučuji pro interakci s Gitem používat spíše [příkazovou řádku](git-cli.html) nebo externího Git klienta a z podpory v NetBeans využívat jen integraci v editoru (zvýraznění změněných řádků, procházení historie apod.) Pokud přesto chcete Git ovládat primárně z NetBeans a bojíte se příkazové řádky, následujte tento návod.

První kroky
-----------

0. Vygenerujte si svůj SSH klíč, pokud ho ještě nemáte, a jeho veřejnou část [přidejte do GitLab](https://gitlab.fit.cvut.cz/keys).
1. Inicializujte nový Git repozitář pro váš projekt, pokud jste tak již neučinili;
   * klikněte pravým tlačítkem myši na váš projekt ve stromu projektů (Window → Projects),
   * dále Git → Initialize, potvrďte „OK“.
2. Proveďte _commit_ do (lokálního) repozitáře;
   * Git → Commit,
   * napište _stručný_ log vystihující provedené změny,
   * zkontrolujte, zda je správně nastavený „Author“ a „Commiter“,
   * označte v seznamu souborů pouze ty, které chcete _commitnout_,
   * nakonec potvrďte klikem na „Commit“.
3. Proveďte _push_ provedených změn do vzdáleného repozitáře;
   * Team → Remote → Push…,
   * vyplňte požadované údaje;
      * Repository URL: SSH adresa repozitáře, kterou vidíte na GitLab hned pod menu (ve tvaru `git@gitlab.fit.cvut.cz:<YOUR_PROJECT>.git`),
      * Private/Public Key / Private Key File: vyberte váš _soukromý_ SSH klíč, který jste si vygenerovali (musí být ve formátu OpenSSH!);
   * v dalším kroku vyberte lokální a vzdálenou větev (`master -> master`),
   * kliknutím na „Finish“ se provede _push_ na GitLab.
