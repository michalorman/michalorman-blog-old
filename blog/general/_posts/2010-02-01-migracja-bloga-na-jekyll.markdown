---
layout: post
title: Migracja bloga z Wordpress na Jekyll
description: Migracja bloga z systtemu Wordpress na statyczne strony generowane z użyciem narzędzia Jekyll.
keywords: wordpress jekyll Michał Orman blog
---
No i dałem się namówić. Przeniosłem swojego bloga z kontroli Wordpress'a na rzecz
statycznych stron generowanych za pomocą narzędzia [Jekyll](http://github.com/mojombo/jekyll).
Ostatnie dni to było wielkie tworzenie layoutu (w oparciu o mój poprzedni layout
[Fluid Blue theme](http://srinig.com/wordpress/themes/fluid-blue/) dla WP), tworzenie
szablonów oraz migrowanie postów.

Jekyll wprawdzie nie jest platformą publikacji. Jest to narzędzie do generowania
stron statycznych na podstawie zdefiniowanych szablonów ze szczególnym wsparciem
dla blogów. Narzędzie to stworzone jest w języku Ruby, instalowane jako Gem. Wykorzystuje
język znaczników [markdown](http://pl.wikipedia.org/wiki/Markdown) do formatowania
dokumentów a także [Liquid](http://www.liquidmarkup.org/). Połączenie to daje w
wyniku całkiem fajne środowisko do tworzenia - generowania - blogów.

Dodatkowo użyłem [Disqus'a](http://disqus.com/) do obsługi komentarzy w postach.
Platforma ta pozwala na proste i szybkie dodawanie usługi komentarzy poprzez
dodanie kilku tagów JavaScript'owych. Komentarze przetwarzane są w [chmurze](http://pl.wikipedia.org/wiki/Cloud_computing)
toteż nie muszę się martwić backapowaniem i ewentualną ich migracją.

Oto jakie są główne zalety tego rozwiązania:

* Strony są statyczne - ładują się dużo szybciej, nie trzeba bawić się z jakąkolwiek
konfiguracją serwera WWW.
* Dane trzymane są na dysku pod kontrolą Git-a, przez co nie muszę martwić się
backupowaniem danych, nie muszę być online by edytować posty, wrzucenie na serwer
to po prostu skopiowanie ich (czyli migracja w 5 sekund).
* Komentarze przetwarzane w chmurze, czyli znów backup i migracja z głowy.
* Pełna kontrola nad wyglądem strony.

Oczywiście podejście to wymagało ode mnie stworzenia szablonu i layoutu strony,
jednakże efekt końcowy daje lepszą frajdę. No i lepsza jest kontrola nad ostatecznym
wyglądem strony. Do definiowania wyglądu możemy używać standardowego HTML'a i
CSS'a, jednakże możemy również użyć [Haml'a](http://sass-lang.com/) i [Sass'a](http://sass-lang.com/).
Ja na razie wykorzystuję tę pierwszą parę.

Pewnie jeszcze będę zmieniał wiele rzeczy w wyglądzie bloga. Na razie przemigrowałem
z Wordpressa i zobaczymy jak się będzie pracowało z Jekyll'em. Kolejnym etapem będzie
stworzenie kilku tasków [Rake'owych](http://rake.rubyforge.org/) aby ułatwić sobie niektóre
zadania (jak tworzenie plików archiwum itp.). Jeżeli ktoś jest ciekawy jak wygląda
kod źródłowy można go [podejrzeć na moim profilu GitHub](http://github.com/michalorman/michalorman.pl).