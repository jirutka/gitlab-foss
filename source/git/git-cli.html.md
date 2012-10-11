---
title: Git v příkazové řádce
---

Git v příkazové řádce
=====================

Git vznikl na Linuxu, jeho tvůrcem je sám [Linus Torvalds](http://www.youtube.com/watch?v=4XpnKHJAok8), takže je primárně navržený pro ovládání z příkazové řádky (grafické nástroje pro něj ale samozřejmě také existují). Nemusíte se toho vůbec obávat, jakmile si nastudujete základy a pochopíte filosofii Gitu, tak to bude hračka.


První kroky
-----------

0. Vygenerujte si svůj SSH klíč, pokud ho ještě nemáte, a jeho veřejnou část [přidejte do GitLab](https://gitlab.fit.cvut.cz/keys).
1. Nastavte si své nacionále, pokud jste tak již neučinili;
   * `git config --global user.name "Kevin Flynn"`,
   * `git config --global user.email "kevin@flynn.com"`.
2. Inicializujte nový lokální repozitář v kořenovém adresáři vašeho projektu;
   * `git init`
3. Vytvořte `.gitignore` se vzory cest souborů/adresářů, které nechcete verzovat (např. cílový adresář pro zkompilovaný kód);
   * přehledný návod najdete v [nápovědě GitHubu](https://help.github.com/articles/ignoring-files).
4. Přidejte všechny soubory, které chcete _commitnout_, do indexu;
   * jednotlivě: `git add file1 file2`,
   * nebo všechny od aktuálního adresáře dál, vyjma ignorovaných: `git add .`,
   * příkazem `git status` si pak můžete zkontrolovat, co zrovna máte v indexu.
5. Proveďte první _commit_;
   * `git commit` (měl by se vám otevřít editor),
   * napište _stručný_ log vystihující provedené změny,
   * nebo předejte text logu jako argument příkazu `git commit -m "initial commit"`.
6. Přidejte vzdálený repozitář na GitLabu;
   * `git remote add origin git@gitlab.fit.cvut.cz:<YOUR_PROJECT>.git` (vaši adresu vidíte na GitLabu hned pod menu).
7. Proveďte první _push_ do vzdáleného repozitáře;
   * `git push -u origin master` (později už stačí pouze `git push`).
8. Gratuluji, provedli jste první _commit_ a nahráli ho na GitLab… že to ani nebolelo?


Další zdroje
------------

* [try.github.com](http://try.github.com) velice hezké interaktivní prostředí pro naučení Gitu
* [help.github.com](https://help.github.com/articles/set-up-git) podrobný návod pro začátečníky na všechny platformy
* [git-scm.com](http://git-scm.com/book/en/) chcete-li vědět víc, určitě si přečtěte tuto knížku
