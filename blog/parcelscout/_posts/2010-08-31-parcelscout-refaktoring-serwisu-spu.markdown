---
layout: post
title: ParcelScout - refaktoring serwisu SPU
description: Refaktoring serwisu SPU aplikacji ParcelScout.
keywords: JSON XML Spring MVC ParcelScout SPU Java Tomcat Content-Type
---
W [poprzednim](/blog/2010/08/parcelscout-tworzenie-serwisu-spu-w-spring-mvc-i-xstream/) poście stworzyłem pierwszą
wersję serwisu SPU. Niestety nie do końca odpowiadała ona pierwotnym [założeniom](/blog/2010/08/parcelscout-zalozenia-i-architektura/).
Dodatkowo Andrzej w komentarzach zasugerował kilka problemów, z którymi on się spotkał implementując serwisy RESTful-owe.
Postanowiłem zatem upiec dwie pieczenie na jednym ogniu. Oprócz dostosowania aplikacji do pierwotnych założeń postanowiłem
dodać odpowiedzi w formacie JSON i sprawdzić jak będzie wyglądało przełączanie się pomiędzy formatami zarówno za pomocą
rozszerzenia jak i parametru Content-Type. Zacznijmy jednak od rzeczy najprostszych, czyli sformatowania XML-a, tak
aby przedstawiał ten, który sobie założyłem.

## Formatowanie XML-a w XStream

Oto co sobie zakładałem:

{% highlight xml %}
<response status="101">
  <package id="0008316649">
    <position latitude="53.43" longitude="14.529" />
  </package>
</response>
{% endhighlight %}

W tej chwili wynik niczym nie przypomina tego zakładanego (pomijając nawet wycięte znaki końca linii):

{% highlight xml %}
<parcel><id>1</id><latitude>54.43</latitude><longitude>14.529</longitude></parcel>
{% endhighlight %}

Doprowadzenie do wymaganej postaci okazuje się banalnie proste. Wystarczy utworzyć strukturę modelu wraz z odpowiednimi adnotacjami:

{% highlight java %}
@XStreamAlias("response")
public class TrackResponse {
    @XStreamAsAttribute
    private Integer status = 101;

    @XStreamAlias("package")
    private Package parcel;

    // settery i gettery...
}
{% endhighlight %}

Warto zauważyć, iż nie mogąc użyć jako nazwy pola słowa ``package`` musiałem użyć ``parcel`` i nałożyć
adnotację ``@XStreamAlias`` aby pole miało właściwą nazwę.

{% highlight java %}
public class Package {

    @XStreamAsAttribute
    private Integer id;

    private Position position;

    // settery i gettery...
}
{% endhighlight %}

W tym przypadku nie potrzebujemy na poziomie klasy deklarować adnotacji ``@XStreamAlias`` ponieważ nazwa elementu brana jest
z nazwy pola klasy zawierającej (czyli ``TrackResponse``).

{% highlight java %}
public class Position {

    @XStreamAsAttribute
    private Double latitude;

    @XStreamAsAttribute
    private Double longitude;

    // settery i gettery...
}
{% endhighlight %}

Adnotacji ``@XStreamAsAttribute`` używamy na tych polach, które w wynikowym XML-u mają być atrybutami elementu a nie
elementami wewnątrz.

## Zmiana formatu żądania z REST-owego na query string

Normalnie w tego typu serwisach nie spotyka się typowego REST-owego formatu adresów URI (np. ``/track/10``). Zwykle takie
zapytania posiadają więcej parametrów, niż jak to ma miejsce w przypadku trywialnej aplikacji SPU. Stąd też częściej używa się query
stringów (nie wiem nawet jaki jest polski odpowiednik tego terminu). Nasz adres powinien zatem wyglądać następująco:
``/track?packageId=10``.

Zmiana formatu zadania sprowadza się do podmiany mapowania i jednej adnotacji:

{% highlight java %}
@RequestMapping(value = "/track", method = RequestMethod.GET)
public ModelAndView getParcelPosition(@RequestParam Integer parcelId) {
    Parcel parcel = parcelService.getParcel(parcelId);
    return new ModelAndView("parcelXmlView", "parcel", parcel);
}
{% endhighlight %}

Zamiast adnotacji ``@PathVariable`` używamy ``@RequestParam`` i tyle.

## Dodanie odpowiedzi w formacie JSON

Kolejna część refaktoringu dotyczy się dodania odpowiedzi w formacie JSON. Okazuje się, że Spring MVC posiada specjalną
klasę widoku, która służy do generowania wyników w tym formacie. Tą klasą jest klasa ``MappingJacksonJsonView``. Aby móc
z niej skorzystać najpierw musimy dodać zależność do ``jackson-mapper-asl`` w pliku ``pom.xml``:

{% highlight xml %}
<dependency>
    <groupId>org.codehaus.jackson</groupId>
    <artifactId>jackson-mapper-asl</artifactId>
    <version>1.5.6</version>
</dependency>
{% endhighlight %}

Teraz musimy stworzyć odpowiedni komponent. Robimy to w pliku ``track-servlet.xml``:

{% highlight xml %}
<bean id="responseJsonView" class="org.springframework.web.servlet.view.json.MappingJacksonJsonView" />
{% endhighlight %}

Komponent ten będzie odpowiedzialny za renderowanie odpowiedzi w formacie JSON. Pamiętajmy, że Spring MVC pozwala
nam łączyć model z widokiem po nazwach. Jeden sposób został przedstawiony w poprzednim poście, teraz skorzystam z
odrobinę innego, czyli wartości zwracanej z metody kontrolera:

{% highlight java %}
@RequestMapping(value = "/track.json", method = RequestMethod.GET)
public String getPackagePositionInJson(@RequestParam Integer packageId, Model model) {
    TrackResponse response = parcelService.getTrackInfo(packageId);
    model.addAttribute("response", response);
    return "responseJsonView";
}
{% endhighlight %}

Mapujemy żądania ``/track.json`` na metodę ``getPackagePositionInJson()`` standardowo za pomocą ``@RequestMapping``. Parametrami
metody są identyfikator paczki wzięty z żądania, oraz obiekt modelu, który będzie używany w widoku do wyrenderowania odpowiedzi
w formacie JSON. Jedyne co musimy zrobić to pobrać odpowiednie dane o paczce i ustawić je jako atrybut modelu a następnie zwrócić
wartość odpowiadającą nazwie komponentu widoku, który ma wyrenderować odpowiedź. Spring MVC zajmie się odpowiednim połączeniem modelu
i widoku,

Podobnie postępujemy z metodą renderującą odpowiedź w formacie XML:

{% highlight java %}
@RequestMapping(value = "/track.xml", method = RequestMethod.GET)
public String getPackagePositionInXml(@RequestParam Integer packageId, Model model) {
    //...
    return "responseXmlView";
}
{% endhighlight %}

## Mapowanie na podstawie parametru Content-Type

Mamy już generowanie odpowiedzi na podstawie formatu (&#42;.xml lub &#42;.json). A co z parametrem Content-Type?
Otóż okazuje się, że adnotacja ``@RequestMapping`` posiada jeszcze jeden parametr: ``headers`` zawężający dopasowanie adresu
właśnie o parametry nagłówka HTTP. Jeżeli chcemy mapować z wykorzystaniem Content-Type potrzebujemy dwóch dodatkowych metod
z adnotacjami w kontrolerze:

{% highlight java %}
@RequestMapping(value = "/track", method = RequestMethod.GET, headers = "content-type=application/xml")
public String trackPackagePositionInXml(@RequestParam Integer packageId, Model model) {
    return getPackagePositionInXml(packageId, model);
}

@RequestMapping(value = "/track", method = RequestMethod.GET, headers = "content-type=application/json")
public String trackPackagePositionInJson(@RequestParam Integer packageId, Model model) {
    return getPackagePositionInJson(packageId, model);
}
{% endhighlight %}

Potrzebujemy nowych metod, ponieważ nie możemy nałożyć dwóch tych samych adnotacji na jedną metodę, a dodając parametr
``headers`` do poprzednich zawężalibyśmy jednocześnie po rozszerzeniu i Content-Type, a nie do końca o to nam chodzi.

W tym momencie refaktoring został skończony, możemy przejść do testowania.

## Szybkie testy

Pewnie wypadałoby napisać tutaj jakieś testy integracyjne, ale na razie nie chce mi się tego robić, więc
posłużę się jedynie konsolą:

{% highlight bash %}
$ curl http://localhost:8080/spu-service/track.xml?packageId=10
<response status="101"><package id="10"><position latitude="53.43" longitude="14.529"/></package></response>

$ curl http://localhost:8080/spu-service/track.json?packageId=10
{"response":{"package":{"id":10,"position":{"latitude":53.43,"longitude":14.529}},"status":101}}
{% endhighlight %}

A teraz XML z wykorzystaniem Content-Type:

{% highlight bash %}
$ curl -v -H "Content-Type: application/xml" http://localhost:8080/spu-service/track?packageId=10
* About to connect() to localhost port 8080 (#0)
*   Trying ::1... connected
* Connected to localhost (::1) port 8080 (#0)
> GET /spu-service/track?packageId=10 HTTP/1.1
> User-Agent: curl/7.19.6 (x86_64-unknown-linux-gnu) libcurl/7.19.6 OpenSSL/0.9.8k zlib/1.2.3 libidn/1.10
> Host: localhost:8080
> Accept: */*
> Content-Type: application/xml
>
< HTTP/1.1 200 OK
< Server: Apache-Coyote/1.1
< Content-Type: application/xml
< Content-Language: pl-PL
< Content-Length: 108
< Date: Tue, 31 Aug 2010 18:00:44 GMT
<
* Connection #0 to host localhost left intact
* Closing connection #0
<response status="101"><package id="10"><position latitude="53.43" longitude="14.529"/></package></response>
{% endhighlight %}

I JSON:

{% highlight bash %}
$ curl -v -H "Content-Type: application/json" http://localhost:8080/spu-service/track?packageId=10
* About to connect() to localhost port 8080 (#0)
*   Trying ::1... connected
* Connected to localhost (::1) port 8080 (#0)
> GET /spu-service/track?packageId=10 HTTP/1.1
> User-Agent: curl/7.19.6 (x86_64-unknown-linux-gnu) libcurl/7.19.6 OpenSSL/0.9.8k zlib/1.2.3 libidn/1.10
> Host: localhost:8080
> Accept: */*
> Content-Type: application/json
>
< HTTP/1.1 200 OK
< Server: Apache-Coyote/1.1
< Pragma: no-cache
< Cache-Control: no-cache, no-store, max-age=0
< Expires: Thu, 01 Jan 1970 00:00:00 GMT
< Content-Type: application/json;charset=UTF-8
< Content-Language: pl-PL
< Transfer-Encoding: chunked
< Date: Tue, 31 Aug 2010 18:01:33 GMT
<
* Connection #0 to host localhost left intact
* Closing connection #0
{"response":{"package":{"id":10,"position":{"latitude":53.43,"longitude":14.529}},"status":101}}
{% endhighlight %}

Działa prawidłowo.

## Podsumowanie

Najpierw zmieniłem format XML-a reorganizując model i dodając kilka adnotacji XStream. Potem zmieniłem format
żądania tak, aby korzystał z query strings (wykorzystując adnotację ``@RequestParam``). W końcu dodałem renderowanie
odpowiedzi w formacie JSON oraz mapowanie formatów XML/JSON na bazie rozszerzenia i Content-Type. Zmian sporo, ale
okazało się, że Spring MVC daje nam świetne wsparcie dla tego typu aplikacji i refaktoring nie okazał się specjalnie
bolesny (nawet przy założeniu, że model jest banalnie prosty). Muszę przyznać, że zaimponowała mi łatwość z jaką przyszło
mi zmodyfikowanie aplikacji i jestem bardzo ciekaw jak w porównaniu ze Spring MVC wypadną aplikacje pisane w pozostałych
technologiach.

Standardowo kod do wglądu na moim profilu GitHub pod adresem: [http://github.com/michalorman/parcelscout/tree/master/work/spu-service/](http://github.com/michalorman/parcelscout/tree/master/work/spu-service/)