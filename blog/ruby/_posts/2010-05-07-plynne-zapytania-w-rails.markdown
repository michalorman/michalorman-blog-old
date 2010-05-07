---
layout: post
title: Płynne zapytania w Rails
description: W inżynierii oprogramowania znany jest termin płynnych interfejsów (ang. fluent interfaces). W rails przy pomocy dyrektywy named_scope możemy korzystać z tej techniki do tworzenia płynnych zapytań.
keywords: Rails fluent interface interfaces płynne płynny interfejs interfejsy named_scope searchlogic
navbar_pos: 1
---
Inżynieria Oprogramowania opracowała termin [płynnych interfejsów](http://en.wikipedia.org/wiki/Fluent_interface)
(ang. fluent interfaces) jako pewien szczególny sposób projektowania API klasy, tak aby można było wykonywać na obiektach
tej klasy pewne czynności przy użyciu czytelniejszego kodu. Czytając taki kod mamy niemal wrażenie, że czytamy
książkę. Przykładem takiego API może być pewna forma wzorca [Builder](http://en.wikipedia.org/wiki/Builder_pattern):

{% highlight java %}
kawa = Kawa.czarna().goraca().bez_cukru().ze_smietanka();
{% endhighlight %}

Prawda, że czytelne? Podobny rodzaj interfejsów jest często wykorzystywane we wszelkiej maści frameworkach do
mockowania np. [Mockito](http://mockito.org/):

{% highlight java %}
List list = new ArrayList();
List spy = mock(ArrayList.class, withSettings()
                .spiedInstance(list)
                .defaultAnswer(CALLS_REAL_METHODS)
                .serializable());
{% endhighlight %}

Tego typu interfejsy można wykorzystywać nie tylko do budowania obiektów. Są one praktyczne także w przypadku
wyciągania kolekcji z bazy danych. Okazuje się, że framework [Rails](http://rubyonrails.org/) daje nam ciekawą
technikę łatwego tworzenia tego typu interfejsów, są to tzw. named scopes (zakresy nazwane?).

## Płynne interfejsy z named scope

Załóżmy, że mamy taki oto prosty model biznesowy. Prowdzaimy wypożyczalnię samochodów i w bazie danych ewidencjonujemy
zarówno samochody, opisywane przez model i markę, jak i zamówienia, które składane są na jeden samochód i przechowują
datę złożenia zamówienia. Chcemy teraz zaimplementować moduł audytowy, pozwalający nam na wyciąganie różnych
zestawień dotyczących zamówień. Powiedzmy, że potrzebujemy wylistować wszystkie zamówienia bieżące, czyli takie, które
dokonane zostały dnia dzisiejszego. Oczywiście moglibyśmy napisać to tak:

{% highlight ruby %}
RentOrder.all(:conditions => { :date => Date.current })
{% endhighlight %}

Mimo iż działa nie jest to podejście dobre. Po pierwsze ciężko jest na pierwszy rzut oka zrozumieć co autor miał
na myśli, musimy się nieco wgryźć w to wyrażenie, aby zrozumieć co się dzieje. Po drugie niszczy to [enkapsulację](http://pl.wikipedia.org/wiki/Hermetyzacja), ponieważ obiekt wywołujący
takie zapytanie (którym potencjalnie będzie kontroler) musi znać wewnętrzną implementację klasy ``RentOrder``. Po
trzecie takie podejście nie wspiera zasady [DRY](http://pl.wikipedia.org/wiki/DRY) przez co w każdym miejscu gdzie
będziemy musieli odwołać się do tej kolekcji danych, będziemy musieli utworzyć podobne wyrażenie. Generalnie lipa,
ale Rails przychodzi nam z pomocą i pozwala takie zapytania umieścić w tzw. named scopes. Robimy to używając dyrektywy
``named_scope`` w naszym modelu:

{% highlight ruby %}
class RentOrder < ActiveRecord::Base
  belongs_to :car

  named_scope :current, :conditions => { :date => Date.current }
end
{% endhighlight %}

Dzięki temu pobranie bieżących zamówień możemy skrócić do:

{% highlight ruby %}
RentOrder.current
{% endhighlight %}

Zwiększyliśmy hermetyzację, oraz jesteśmy zgodni z zasadą DRY, pozostaje jednak pytanie: po co nam jakieś named
scope'y, czy nie mogliśmy utworzyć (użyć) metody statycznej? Dlaczego nie lepiej było wywołać:

{% highlight ruby %}
RentOrder.find_all_by_date(Date.current)
{% endhighlight %}

Ponieważ ponownie niszczymy enkapsulację. Zmiana sposobu przechowywania daty (np. zmiana nazwy atrybutu na
``order_date``) spowoduje, że powyższy kod przestanie działać (o czym nawet się nie dowiemy nie posiadając testów).
Jest jednak jeszcze jeden powód, dla którego lepiej utworzyć named scope'a. Mianowicie zakresy te można ze
sobą łączyć (ang. chaining). Co to w praktyce oznacza? Zobaczmy na przykładzie. Dodajmy kolejnego scope'a. Tym
razem chcielibyśmy mieć możliwość pobrania wszystkich zamówień, które dotyczą konkretnej marki samochodu. Taki
scope wyglądałby następująco:

{% highlight ruby %}
class RentOrder < ActiveRecord::Base
  belongs_to :car

  named_scope :current, :conditions => { :date => Date.current }
  named_scope :for_mark, lambda { |mark| { :joins => [:car], :conditions => ["cars.mark = ?", mark] } }
end
{% endhighlight %}

W tym przypadku niestety składnia nie jest zbyt przyjazna, ale gdy się nabierze trochę wprawy to przestaje
być ona taka enigmatyczna. Mamy tutaj przykład dwóch rzeczy. Po pierwsze przesyłania parametru do
named scope'a. Robimy to za pomocą wyrażenia ``lambda`` dostarczając jej blok z naszym parametrem. Kolejna rzecz
to dołączenie tabeli ``Car`` do naszego zapytania (parametr ``:joins``). Dzięki tej technice możemy
poszukać wszystkich zamówień dotyczących samochodu marki Audi w następujący sposób:

{% highlight ruby %}
RentOrder.for_mark('Audi')
{% endhighlight %}

Jednakże, co jeszcze ciekawsze, łącząc te dwa named scope'y możemy wyszukać wszystkie bierzące zamówienia samochodów
dotyczące konkretnej marki. Zrobilibyśmy to tak:

{% highlight ruby %}
RentOrder.current.for_mark('Audi')
{% endhighlight %}

Rails połączy te zapytania, generując w wyniku jedno, odpowiednio skonstruowane zapytanie SQL:

{% highlight sql %}
SELECT "rent_orders".* FROM "rent_orders" INNER JOIN "cars" ON "cars".id = "rent_orders".car_id WHERE ((cars.mark = 'Audi') AND ("rent_orders"."date" = '2010-05-07'))
{% endhighlight %}

Generalnie w przypadku named scope możemy wykorzystywać te same parametry, jak przy każdym wyszukiwaniu
metodą ``find``. Jednakże sa pewne ograniczenia. Po pierwsze Rails zgłupieje jak w kilku scope'ach znajdzie
poustawiane takie parametry jak ``:limit`` czy ``:order``, dlatego też trzeba być ostrożnym umieszczając
je w scope'ach. Kolejny problem, dotyczy już samego łączenia scope'ów. Przypuścmy, że chcielibyśmy zrobić coś
takiego:

{% highlight ruby %}
RentOrder.current.for_mark('Audi').for_mark('Renault')
{% endhighlight %}

Niestety taka kombinacja nie zadziała tak jak byśmy tego chcieli, ponieważ poszczególne warunki są łączone
z użyciem operatora AND w efekcie dostajemy takie zapytanie:

{% highlight sql %}
SELECT "rent_orders".* FROM "rent_orders" INNER JOIN "cars" ON "cars".id = "rent_orders".car_id WHERE (((cars.mark = 'Renault') AND (cars.mark = 'Audi')) AND ("rent_orders"."date" = '2010-05-07'))
{% endhighlight %}

Jeżeli nie mamy w bazie samochodów, które mają markę jednocześnie Audi i Renault to zapytanie zwróci nam pustą
tablicę. Jednakże świadomi ograniczeń named scope'ów możemy korzystać z nich tworząc rozbudowane zapytania z
małych, prostych i reużywalnych klocków. Dodatkowo nasza logika jest hermetycznie zamknięta i znajduje się tam,
gdzie być powinna, czyli w modelu.

## Podsumowanie

Płynne interfejsy to świetna metoda tworzenia czytelnych dla ludzkiego oka API. Dzięki nim możemy tworzyć
ciągi wywołań, które niemal same się będą dokumentowały. Framework Rails pozwala nam tę konwencję przenieść
na zapytanie SQL-owe. Dzięki dyrektywie ``named_scope`` możemy utworzyć proste zapytania, które będziemy
potem mogli płynnie łączyć ze sobą. Jest to prosta i elegancka metoda budowania skomplikowanych
zapytań z prostych klocków, dotego zapewniająca dobrą hermetyzację oraz wspierająca zasadę DRY.