---
title: Úvodní seznámení
---

# Úvodní seznámení

GitLab je moderní (nejen) webový správce Git repozitářů, velmi inspirovaný populární službou [GitHub](https://github.com). Svou koncepcí je tedy zaměřený primárně na práci se zdrojovým kódem, čímž se odlišuje od klasických „manažerských“ nástrojů typu Redmine. Oproti GitHubu je určený do prostředí intranetu, pro neveřejné projekty.

Hlavní komponentu tvoří komfortní prohlížeč kódu s úzkou návazností na Git. Stejně jako GitHub umožňuje psaní komentářů k jednotlivým _commitům_ či přímo konkrétním řádkám kódu. Poskytuje minimalistický _issue tracking_, který uživatele neobtěžuje zbytečnými políčky. Samozřejmě nechybí ani jednoduchá wiki a všudepřítomná podpora syntaxe Markdown.

Podporuje tzv. _merge requests_ (obdoba _pull request_ z GitHubu) – vytvoření požadavku na začlenění _commitů_ z jedné vývojové větve do druhé, o kterém pověření členové mohou rozhodnout, zda ho začlenit či nikoli, případně u něj vést diskuzi (vhodné pro revizi kódu od přispěvovatelů).
 

## Jak ho začít používat?

Gitlab běží na adrese https://gitlab.fit.cvut.cz a má do něj přístup kdokoli z akademické obce FIT. Autentizace se provádí proti LDAP serveru FIT, takže se přihlásíte svým loginem a _fakultním_ heslem (ne tím do KOSu). 


## Doporučení

* Domníváte-li se, že by váš projekt mohl být užitečný i lidem mimo fakultu, umístěte ho (zároveň i) na [GitHub](https://github.com)! Máme na něm i vlastní [„organizaci“ ČVUT](https://github.com/cvut), v rámci které je možné vytvářet týmy. Pro přidání do organizace mě kontaktujte na [e-mailu](mailto:jirutjak@fit.cvut.cz).

* Nemáte-li rozumný důvod k utajování (např. pracujete na přísně tajném projektu, stydíte se za svůj kód, …), nastavte svůj projekt jako „veřejný“ pro přihlášené uživatele (tzn. akademickou obci FIT, popř. kolegy z FEL).

* Chcete-li mít větší kontrolu nad hlavní vývojovou větví, tak využívejte _merge requests_.
  + Nastavte hlavní větev _(master)_ jako chráněnou (Commits → Branches → Protected: Branch master protect!) – tím do ni budou moci zapisovat pouze Správci (viz role).
  + Roli Správce dejte pouze hlavním vývojářům, kteří udržují hlavní větev a jsou za projekt zodpovědní. 
  + Ostatním přispěvovatelům přidělte roli Vývojář a instruujte je, aby si v případě touhy přispět něčím do projektu vytvořili svou větev a až budou hotovi, tak přes GitLab poslali žádost o začlenění do hlavní větve (merge request). Správce se může na žádost podívat, příp. nad ní diskutovat a přijmout. 

* Diskutujte věcně a _přímo_ nad kódem! GitLab umožňuje psát komentáře i pod jednotlivé _commity_ nebo dokonce řádky kódu.

* Buďte otevření, nebojte se projekt otevřít komunitě (v našem případě akademické obci fakulty) a umožnit ostatním se do něj zapojit.


## Podělte se o svůj názor!

Máte nápad na nějaké vylepšení či kritiku? Chtěli byste v rámci semestrální či bakalářské práce napsat nějaké rozšíření do Gitlabu a přispět tím své fakultě i _open-source_ komunitě? Napište mi na [e-mail](mailto:jirutjak@fit.cvut.cz)! Chyby prosím hlaste do [issue-trackingu](https://github.com/cvut/gitlabhq/issues) v našem _forku_ projektu na GitHubu.

Berte prosím v potaz, že já _nejsem_ tvůrce Gitlabu, pouze zajišťuji jeho provoz a upravuji ho pro potřeby FIT, ve svém volném čase. Malé změny zatím zvládám sám, na případné větší by se vypsala nějaká semestrální či bakalářská práce.

Moji motivací je prosazování moderních technologií, které nám usnadní a zpříjemní práci nebo studium. Pryč se zastaralými a neefektivními nástroji či postupy práce, se kterými se tu musíme potýkat!

Gitlab je **open-source** software postavený na **Ruby on Rails**. [→ více](http://gitlabhq.com/)
