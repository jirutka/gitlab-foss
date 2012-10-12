---
title: Git v IntelliJ IDEA 11
---

Git v IntelliJ IDEA 11
======================

Inicializace nového repozitáře
------------------------------

Tento scénář platí pro případ, kdy jste na GitLabu právě vytvořili nový projekt, jehož repozitář zatím zeje prázdnotou.

IDEA neumí použít ještě neinicializovaný vzdálený repozitář, takže tento krok musíte udělat přes příkazovou řádku.

0. Vygenerujte si svůj SSH klíč, pokud ho ještě nemáte, uložte na správné místo (typicky `${HOME}/.ssh`) a jeho veřejnou část [přidejte do GitLab](https://gitlab.fit.cvut.cz/keys).
1. Na OS X a Linux změňte nastavení SSH klienta v IDEA z _built-in_ na _native_;
   * otevřete dialog „Preferences…“,
   * Version Control → Git,
      * SSH Executable: Native.
2. Přes příkazovou řádku inicializujte nový lokální repozitář a nastavte vzdálený repozitář na GitLabu;
   * otevřete okno terminálu,
   * přesuňte se do kořenového adresáře vašeho projektu,
   * inicializujte repozitář: `git init`,
   * přidejte vzdálený repozitář: `git remote add origin git@gitlab.fit.cvut.cz:<YOUR_PROJECT>.git` (vaši adresu vidíte na GitLabu hned pod menu).
3. Otevřete svůj projekt v IDEA a povolte integraci Git;
   * VCS → Enable Version Control Integration…,
   * z nabídky vyberte Git a potvrďte (pokud chybí, tak nemáte aktivovaný Git modul v IDEA).
4. Přidejte všechny soubory projektu do indexu;
   * klikněte pravým tlačítkem myši na váš projekt ve stromu projektů (View → Tool Windows → Project),
   * dále Git → Add.
5. Proveďte _commit_ do (lokálního) repozitáře;
   * VCS → Commit Changes…,
   * označte v seznamu souborů pouze ty, které chcete _commitnout_,
   * do pole „Author“ vyplňte vaše jméno, příjmení a e-mail (např. `Kevin Flynn <kevin@flynn.com>`),
   * napište stručný komentář vystihující provedené změny,
   * klikněte na „Commit“, nebo „Commit and Push“, chcete-li změny rovnou přenést do GitLab repozitáře.
6. Proveďte _push_ provedených změn do vzdáleného repozitáře;
   * VCS → Git → Push…,
   * označte „Push current branch to alternative branch“ a zvolte cílovou větev (typicky `master`),
   * kliknutím na „Push“ se publikují vaše změny do vzdáleného repozitáře na GitLab.


Import projektu z existujícího repozitáře
-----------------------------------------

Tento scénář platí typicky pro případ, kdy vás kolega přidá do již rozběhnutého projektu (neprázdný repozitář), na kterém nyní máte začít pracovat.

0. Vygenerujte si svůj SSH klíč, pokud ho ještě nemáte, uložte na správné místo (typicky `${HOME}/.ssh`) a jeho veřejnou část [přidejte do GitLab](https://gitlab.fit.cvut.cz/keys).
1. Na OS X a Linux změňte nastavení SSH klienta v IDEA z _built-in_ na _native_;
   * otevřete dialog „Preferences…“,
   * Version Control → Git,
      * SSH Executable: Native.
2. Naklonujte vzdálený repozitář z GitLab;
   * VCS → Checkout from Version Control → Git,
   * vyplňte požadované údaje;
      * Git Repository URL: SSH adresa repozitáře, kterou vidíte na GitLab hned pod menu (ve tvaru `git@gitlab.fit.cvut.cz:<YOUR_PROJECT>.git`),
      * Parent Directory & Directory Name: cílový adresář, do kterého se projekt uloží,
   * vyzkoušejte spojení s repozitářem kliknutím na „Test“,
   * kliknutím na „Clone“ se vytvoří váš lokální klon vzdáleného repozitáře a IDEA by vám měla nabídnout otevření projektu.
