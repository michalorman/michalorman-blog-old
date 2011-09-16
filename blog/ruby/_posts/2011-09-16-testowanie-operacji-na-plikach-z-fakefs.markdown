---
layout: post
title: Testowanie operacji na plikach z FakeFS
description: Testowanie operacji na plikach z FakeFS
keywords: FakeFS ruby
---
Testowanie operacji na plikach może być problematyczne. Z jednej strony
nie chcemy zaśmiecać swojego systemu jakimiś plikami
generowanymi przez testy i martwić się, aby posprzątać po testach, z
drugiej mockowanie klas I/O może być uciążliwe, oraz powoduje, że testy są
bardzo wrażliwe na zmianę implementacji (nawet jeśli działanie metody
pozostało bez zmian). Testując operacje na plikach na prawdę
chcielibyśmy tworzyć te pliki, sprawdzać ich istnienie, atrybuty czy
zawartość.

Rozwiązaniem tego problemu jest
[FakeFS](https://github.com/defunkt/fakefs). Biblioteka ta tworzy nam
sztuczny system plików w pamięci operacyjnej. Dzięki **FakeFS** możemy
tworzyć i testować pliki jednocześnie nie zaśmiecając sobie dysku.

Ponieważ biblioteka ta modyfikuje działanie biblioteki I/O możemy
natknąć się na problemy jeżeli nasz test powinien otworzyć plik z
prawdziwego systemu pliku. Na szczęście FakeFS pozwala nam aktywować i
deaktywować w dowolnym momencie sztuczny system plików. Przykładowo
testując za pomocą [Cucumber'a](http://cukes.info/) do pliku `env`
możemy dodać coś takiego:

{% highlight ruby %}
Before '@fakefs' do
  FakeFS.activate!
end

After '@fakefs' do
  FakeFS.deactivate!
end
{% endhighlight %}

Wtedy każdy scenariusz oznaczony przez `@fakefs` będzie wykonywany z
użyciem sztucznego systemu plików.

Używając tej biblioteki nie potrzebujemy korzystać z jakiegoś
dodatkowego API, tworzyć jakiś magicznych obiektów itp. Operujemy na
plikach po prostu korzystając z biblioteki I/O.
