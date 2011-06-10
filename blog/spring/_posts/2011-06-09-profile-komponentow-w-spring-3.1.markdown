---
layout: post
title: Profile Komponentów w Spring 3.1
description: Profile komponentów w Spring 3.1
keywords: spring 3.1 bean definition profile profil
---
Na stronie SpringSource [właśnie
ogłoszono](http://www.springsource.org/node/3149) kolejny release
nadchodzącego Spring'a 3.1. Wcześniej nie miałem zbytnio czasu, aby
przyjrzeć się zmianą w najnowszej wersji tego frameworka, jednak tym
razem, nieco od niechcenia, przeleciałem się po nowych featurach
planowanych dla wersji 3.1. Szczególnie zaintrygował mnie jeden punkt
**Bean Definition Profiles**. Tak! Spring 3.1 pozwalać nam będzie na
definiowanie komponentów w zależności od środowiska w jakim aplikacja
będzie uruchamiana! Koniec z bawieniem się w filtrowanie zasóbów,
profilami i podmienianiem plików z
poziomu mavena! Koniec z męczeniem się, aby to wszystko działało
automatycznie w IDE. Od wersji 3.1 taką funkcjonalność będziemy mieć
wbudowaną w framework!

To co mnie tylko ciekawi to dlaczego twórcy Spring'a kazali nam tak
długo czekać na tak podstawową funkcjonalność. Przecież wszyscy takie
ekwilibrystyki robili na każdym projekcie, więc potrzeba takiego
featura na pewno była już od bardzo dawna.

## Profile Komponentów

Ok przejdźmy do rzeczy. Po co nam w ogóle takie profile? Najbardziej
klasycznym przykładem (i jednocześnie najbardziej frustrującym z
powodu jego braku) jest możliwość konfiguracji kilku baz danych dla
środowiska produkcyjnego, deweloperskiego i testowego. Brakuje tego
zarówno w Spring'u jak i w J2EE/JPA, a przecież oczywistym jest, że dla
każdego z tych środowisk chcemy mieć osobną bazę danych.

Innym przykładem może być możliwość zamiany komponentów komunikujących
się ze zdalnymi serwisami. Wyobraźmy sobie, że korzystamy z usługi
jakiegoś operatora płatności, a ten nie udostępnia nam środowiska
testowego tylko produkcyjne. Testując czy implementując komponent korzystający z tego
API nie chcemy korzystać z produkcyjnego środowiska przynajmniej z 2
powodów:

1. Ktoś przez przepadek (albo celowo ;)) może zostać obciążony
kosztami niezamówionych przez siebie usług, co może wystąpić przy płatnościach obsługiwanych przez
operatorów komórkowych (autentyczna historia z jednego z moich
ostatnich projektów ;)).
2. Nie chcemy bombardować produkcyjnej infrstruktury klienta setkami
zapytań wysyłanymi z automatycznych testów.

W takim przypadku produkcyjny komponent chcemy zastąpić jakimś
mockiem. (Możemy też postawić aplikację symulującą zachowanie zdalnego
serwisu i korzystać z produkcyjnego komponentu ale nacelowanego na symulator.)

Jak widać potrzeba takich profili jest, zobaczmy zatem jak będziemy
mogli definiować profile w Spring'u 3.1.

## Definiowanie Profili

Zgodnie z zapoczątkową w Spring'u 2.5 tendencją mamy dwie możliwości
konfiguracji. Tradycyjnie w pliku XML (co w niektórych przypadkach ma
swoje uzasadnienie) oraz za pomocą adnotacji (co ma uzasadnienie w
przypadkach nie uzasadnionych przez poprzedni przypadek :P).

W przypadku XML-a element ``<beans>`` posiada dodatkowy atrybut
``profile``:

{% highlight xml %}
<beans xmlns="http://www.springframework.org/schema/beans"
       profile="dev">

  <bean id="remoteService" class="org.domain.RemoteServiceStub" />

</beans>
{% endhighlight %}

Możemy w ten sposób utworzyć 2 pliki ``components-dev.xml`` lub
``components-prod.xml`` z odpowiednimi komponentami. W Spring 3.1
możliwe jest także zagnieżdżenie elementu ``<beans>`` przez co możemy
miec wszystkie definicje w jednym pliku (co ma sens przy małej ich
ilości).

### Definiowanie Profili za pomocą ``@Profile``

Alternatywą dla konfiguracji w pliku XML jest konfiguracja za pomocą
adnotacji ``@Profile``. Możemy użyć jej bezpośrednio na komponencie z
podaniem nazwy profilu:

{% highlight java %}
@Profile("dev") @Service
public class RemoteServiceStub { ... }
{% endhighlight %}

Sposób ten jest jednak niezalecany. Zdecydowanie lepiej użyć adnotacji
``@Profile`` jako meta-adnotacji i stworzyć nową adnotację:

{% highlight java %}
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Profile("dev")
pubilc @interface Dev {
}
{% endhighlight %}

I użyć jej na naszym komponencie:

{% highlight java %}
@Dev @Service
public class RemoteServiceStub { ... }
{% endhighlight %}

W ten sposób nie powtarzamy wszędzie nazwy profilu i możemy go
zmienić, lub w ogóle wyłączyć dla szystkich klas w jednym miejscu.

## Aktywowanie Profilu

Ok wiemy jak definiować profile. Pytanie jak powiedzieć kontenerowi
Spring'a, którego ma użyć? Do tego służy parametr
``spring.profiles.active``, który może zostać skonfigurowany poprzez
zmienne systemowe, zmienne systemowe JVM, parametry kontekstowe
servletu lub jako wpis w JNDI.

## Podsumowanie

Tak więc programiści Java znów dostają coś co w innych platformach
jest dostępne od dawna ;). No, ale najważniejsze, że wreszcie mamy
możliwość definiowania zestawu komponentów Spring'owych w zależności
od środowiska uruchomieniowego.

Po więcej informacji odsyłam do:
[http://blog.springsource.com/2011/02/11/spring-framework-3-1-m1-released/](http://blog.springsource.com/2011/02/11/spring-framework-3-1-m1-released/)
[http://blog.springsource.com/2011/02/14/spring-3-1-m1-introducing-profile/](http://blog.springsource.com/2011/02/14/spring-3-1-m1-introducing-profile/)
