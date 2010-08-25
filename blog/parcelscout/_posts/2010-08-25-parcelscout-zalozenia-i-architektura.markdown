---
layout: post
title: ParcelScout - Założenia i architektura
description:
keywords: JavaEE Rails Glassfish Tomcat XML JSON HTTP HTML WebService serwis REST RESTful
---
Mimo, iż ostatnio krucho u mnie z czasem, co odbija się na aktywności na blogu, postanowiłem
rozpocząć cykl nieco praktyczniejszych postów (dotąd były one raczej bardziej teoretyczne).
Postanowiłem utworzyć infrastrukturę, którą roboczo nazwałem **ParcelScout**. Infrastruktura
ta składać się będzie z kilku modułów, tworzonych w różnych technologiach, udostępniających
razem usługę lokalizowania przesyłek.

Oto jak wyglądałaby przykładowa architektura tego rozwiązania:

{% assign i_src='parcel-scout/components_deployment.png' %}
{% assign i_title='Diagram wdrożenia aplikacji ParcelScout' %}
{% include image.html %}

## Scenariusz

Trzy firmy: LHD, SPU oraz Xedef zajmują się usługami dostarczania przesyłek. System ParcelScout
ma na celu udostępnienie jednego interfejsu śledzenia przesyłek niezależnie od tego, która
z firm zajmuje się obsługą konkretnej przesyłki.

Firmy LHD oraz SPU udostępniają usługę pozwalającą na dodanie usługi śledzenia przesyłek do
współpracującej platformy e-commerce. Usługi te dostępne są jako RESTful-owe serwisy. Żądania
wysyłane są z wykorzystaniem protokołu HTTP natomiast odpowiedzi generowane są w formacie XML (SPU)
lub JSON (LHD).

Firma Xedef nie udostępnia jeszcze takiej usługi. Klienci korzystający z usług tej firmy muszą
wejść na witrynę firmy i wypełniając odpowiedni formularz mogą śledzić swoje przesyłki.

Niestety klient, czekający na swoją przesyłkę, musi wiedzieć, z usług której
z firm korzysta sklep w jakim dokonał zakupu, aby wejść na odpowiednią witrynę celem śledzenia
przesyłki. Brakuje mu jednak centralnego miejsca z którego mógłby to robić niezależnie od tego
jaka firma zajmuje się faktycznym jej dostarczeniem.

## Założenia

Tak pokrótce przedstawia się scenariusz. Jak widać ParcelScout ma za zadanie rozwiązanie konkretnego
problemu. Problem ten w celach naukowych zostanie rozwiązany z wykorzystaniem kilku technologii,
aby można było je porównać ze sobą.

De facto mam zamiar napisać 2 wersje aplikacji ParcelScout. Jedna powstanie z wykorzystaniem
frameworka Rails druga zostanie napisana w Javie i zostanie oparta o framework Spring. Obie wersje będą
udostępniać interfejs, w którym żądania wysyłane będą z wykorzystaniem protokołu HTTP, natomiast
odpowiedzi będą w formacie JSON.

Przykładowe żądanie:

{% highlight bash %}
GET http://parcelscout.pl/track?parcelId=0008316649
{% endhighlight %}

Przykładowa odpowiedź:

{% highlight javascript %}
{ "Parcel" : { "id" : "0008316649", "lat" : "53.43", "lon" : "14.529" } }
{% endhighlight %}

Dodatkowo stworzony zostanie klient na platformę Android, który wykorzystując serwis ParcelScout będzie
zaznaczał aktualną pozycję paczki na mapie i wyświetlał użytkownikowi. Być może w przyszłości spróbuję rozwinąć moduł o
wyświetlanie trasy, jaką paczka przebyła.

### API firm przesyłkowych

Firma SPU udostępnia serwis pozwalający śledzić paczkę wykorzystując protokół HTTP i metodę GET tegoż protokołu. Odpowiedź przesyłane
są w formacie XML.

Przykładowe żądanie:

{% highlight bash %}
GET http://spu.pl/whereIs?pid=0008316649
{% endhighlight %}

Przykładowa odpowiedź:

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?> 
<response status="101">
  <package id="0008316649">
    <position latitude="53.43" longitude="14.529" />
  </package>
</response>
{% endhighlight %}

Firma LHD podobnie jak SPU udostępnia serwis korzystający z protokołu HTTP jednak korzysta z metody POST. W przypadku tego serwisu
odpowiedzi wysyłane są w formacie JSON.

Przykładowe żądanie:

{% highlight bash %}
POST /queryPackage
Host: lhd.pl
Accept: */*
Content-Length: 21
Content-Type: application/x-www-form-urlencoded
package_id=0008316649
{% endhighlight %}

Przykładowa odpowiedź:

{% highlight javascript %}
{ "LHDQueryResponse" : {
  "status" : "0 [OK]"
  "PackageInfo" : {
    "package_id" : "0008316649",
    "Position" : {
      "latitude" : "53.43",
      "longitude" : "14.529"
    }
  }
}}
{% endhighlight %}

Firma Xedef nie udostępnia żadnego interfejsu. W jej przypadku trzeba będzie wejść na witrynę firmy, wypełnić
odpowiedni formularz i odczytać odpowiedź z otrzymanego dokumentu w formacie HTML.

## Podsumowanie

W tym wpisie przedstawiłem problem i architekturę rozwiązania, które mam zamiar zaimplementować. W kolejnych wpisach z tego
cyklu będę przedstawiał architekturę poszczególnych komponentów oraz relacjonował kroki ich powstawania. Mam nadzieję,
że takie bardziej praktyczne przedstawienie niektórych platform czy frameworków przyda się komuś zdecydowanie bardziej,
niż czysto teoretyczne dywagacje. Mam również nadzieję, że niektóre me postępowania sprowokują kogoś do dyskusji na temat
takiego czy innego rozwiązania. Takie dyskusje są często bardziej pouczające, niż samo rozwiązywanie problemu.