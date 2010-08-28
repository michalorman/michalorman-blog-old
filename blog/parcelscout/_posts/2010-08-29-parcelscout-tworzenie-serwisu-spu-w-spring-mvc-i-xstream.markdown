---
layout: post
title: ParcelScout - tworzenie serwisu SPU w Spring MVC i XStream
description: Tworzenie serwisu SPU z wykorzystaniem frameworka Spring MVC oraz XStream.
keywords: Spring MVC OXM XStream REST RESTful serwis service
---
Swoje boje z ParcelScout rozpoczynam od stworzenia aplikacji dla firmy SPU. Aplikacja
ta zgodnie z diagramem, który przedstawiłem w [poprzednim poście](/blog/2010/08/parcelscout-zalozenia-i-architektura/)
oparta jest na frameworku Spring i uruchamiana w zwykłym kontenerze serwletów Tomcat.
Zatem zaczynam od stworzenia projektu web-aplikacji:

{% highlight bash %}
mvn archetype:create -DgroupId=pl.michalorman.spu -DartifactId=spu-service -DarchetypeArtifactId=maven-archetype-webapp
{% endhighlight %}

Kolejną rzeczą jest dodanie do pliku ``pom.xml`` zależności Spring-a.

{% highlight xml %}
<properties>
    <org.springframework.version>3.0.4.RELEASE</org.springframework.version>
</properties>

<dependencies>
    <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-oxm</artifactId>
        <version>${org.springframework.version}</version>
    </dependency>
    <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-webmvc</artifactId>
        <version>${org.springframework.version}</version>
    </dependency>
</dependencies>
{% endhighlight %}

Aplikacja SPU korzysta ze Springa w wersji 3.0.4. Ponieważ chcemy aby odpowiedź serwisu była formatowana w XML
do zależności dodałem ``spring-oxm`` natomiast ``spring-webmvc`` posłuży nam do szybkiego wygenerowania widoku.

W tym momencie możemy zająć się naszą aplikacją. W pierwszej kolejności tworzymy prosty model:

{% highlight java %}
public class Parcel {
    private Integer id;
    private String latitude;
    private String longitude;

    // gettery i settery
}
{% endhighlight %}

Mając model potrzebujemy kontrolera. Z pomocą kilku adnotacji Spring'a kontroler tworzymy błyskawicznie:

{% highlight java %}
@Controller
public class ParcelController {
    @Autowired
    private ParcelService parcelService;

    @RequestMapping(value = "/track/{parcelId}", method = RequestMethod.GET)
    public ModelAndView getParcelPosition(@PathVariable Integer parcelId) {
        // ...
    }
}
{% endhighlight %}

Do oznaczenia kontrolera wykorzystujemy adnotację ``@Controller`` natomiast do określenia mapowania żądania
adnotację ``@RequestMapping``. Mapowanie ``/track/{parcelId}`` to tzw. URI template. Dzięki temu
mechanizmowi możemy w mapowaniu używać zmiennych, które będą przekazywane do odpowiednich parametrów metody
oznaczonych adnotacją ``@PathVariable``. Sama implementacja metody ``getParcelPosition()`` zostanie omówiona później.

Za pomocą adnotacji ``@Autowired`` dokonujemy standardowego wstrzyknięcia serwisu, który w chwili obecnej
zwraca przykładowe dane, ale w późniejszym czasie zostanie wzbogacony o wsparcie ORM.

{% highlight java %}
@Service
public class ParcelService {
    public Parcel getParcel(Integer parcelId) {
        Parcel parcel = new Parcel();
        parcel.setId(parcelId);
        parcel.setLatitude("54.43");
        parcel.setLongitude("14.529");
        return parcel;
    }
}
{% endhighlight %}

Pozostaje nam tylko to wszystko pożenić ze sobą i skonfigurować jako web-aplikację. Standardowo musimy zarejestrować
odpowiedni servlet w pliku ``web.xml``:

{% highlight xml %}
<servlet>
    <servlet-name>track</servlet-name>
    <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
    <load-on-startup>1</load-on-startup>
</servlet>

<servlet-mapping>
    <servlet-name>track</servlet-name>
    <url-pattern>/*</url-pattern>
</servlet-mapping>
{% endhighlight %}

Ostatni krok to konfiguracja samego Springa. Robimy to w pliku ``track-servlet.xml``. Tutaj musimy skonfigurować
kilka rzeczy. Po pierwsze musimy powiedzieć Springowi aby poszukał komponentów na bazie adnotacji (inaczej wykorzystał
by tylko te zdefiniowane w pliku XML):

{% highlight xml %}
<context:component-scan base-package="pl.michalorman.spu" />
{% endhighlight %}

Teraz pozostaje nam jedynie widok. W przypadku web-serwisu nie renderujemy widoku w formacie HTML, stąd wszelkie
JSP-y, JSF-y czy AJAX-y nie są nam potrzebne. Framework Spring MVC pozwala nam wykorzystać klasę
``MarshallingView`` w celu utworzenia widoku prosto z obiektu modelu. Faktycznie
generowaniem zajmuje się obiekt implementujący interfejs ``Marshaller``, który przekazujemy
jako parametr konstruktora. Ponieważ chcemy otrzymać wynik w formacie XML wykorzystamy klasę ``XStreamMarshaller``,
która używa biblioteki [XStream](http://xstream.codehaus.org/). Definiujemy zatem komponent, który będzie
odpowiedzialny za renderowanie widoku:

{% highlight xml %}
<bean id="parcelXmlView"
    class="org.springframework.web.servlet.view.xml.MarshallingView">
    <constructor-arg>
        <bean class="org.springframework.oxm.xstream.XStreamMarshaller">
            <property name="autodetectAnnotations" value="true" />
        </bean>
    </constructor-arg>
</bean>
{% endhighlight %}

Teraz jedynie co trzeba zrobić to połączyć wynik działania metody ``getParcelPosition()`` (zdefiniowanej wcześniej)
z owym komponentem. Zacznijmy może od samej metody, bo jeszcze nie pokazałem jej ciała:

{% highlight java %}
@RequestMapping(value = "/track/{parcelId}", method = RequestMethod.GET)
public ModelAndView getParcelPosition(@PathVariable Integer parcelId) {
    Parcel parcel = parcelService.getParcel(parcelId);
    return new ModelAndView("parcelXmlView", "parcel", parcel);
}
{% endhighlight %}

Rezultatem tej metody jest obiekt klasy ``ModelAndView``. Obiekt ten posiada swoją nazwę ``parcelXmlView`` oraz
dokładnie jeden obiekt modelu znajdujący się pod kluczem ``parcel``. Teraz dodajmy deklarację łączące wynik
działania tej metody z wcześniejszą konfiguracją:

{% highlight xml %}
<bean class="org.springframework.web.servlet.view.BeanNameViewResolver" />
{% endhighlight %}

Owym łączeniem zajmie się komponent ``BeanNameViewResolver`` zdefiniowany w pliku ``track-servlet.xml``. Obiekt
ten dla nazwanych widoków wyszuka komponentów o tej samej nazwie (warto zauważyć, że i obiekt zwracany z metody ``getParcelPosition()`` oraz
ten zdefiniowany w pliku ``track-servlet.xml`` nazywają się ``parcelXmlView``) i wykorzysta do wyrenderowania odpowiedzi.

Na zakończenie trzeba jeszcze dodać zależność do ``XStream-a`` w ``pom.xml`` oraz alias na naszym modelu, aby
wygenerowany XML był nieco ładniejszy:

{% highlight java %}
@XStreamAlias("parcel")
public class Parcel {
  //...
}
{% endhighlight %}

W tym momencie utworzyliśmy nasz RESTful-owy web-serwis. Teraz wystarczy uruchomić aplikację na jakimś
Tomcat-cie i możemy testować:

{% highlight bash %}
$ curl http://localhost:8080/spu-service/track/1
<parcel><id>1</id><latitude>54.43</latitude><longitude>14.529</longitude></parcel>
{% endhighlight %}

## Podsumowanie

Wykorzystując Spring MVC utworzenie RESTful-owego web serwisu sprowadziło się do paru adnotacji
i minimum konfiguracji w XML-u. Aplikacja wymaga jeszcze kilku małych szlifów, ale generalnie można ją
uznać za gotową. Pierwszy element infrastruktury ParcelScout już stoi, zobaczymy jak sprawnie pójdzie mi
z resztą.

Kod aplikacji można podejrzeć tutaj:
[http://github.com/michalorman/parcelscout/tree/master/work/spu-service/](http://github.com/michalorman/parcelscout/tree/master/work/spu-service/)