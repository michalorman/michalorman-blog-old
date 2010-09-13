---
layout: post
title: ParcelScout - Serwis RESTowy oparty o Spring MVC
description: Opis tworzenia RESTful-owego serwisu opartego o framework Spring MVC.
keywords: Spring MVC RESTful serwis service JSON XML
---
Teraz kiedy już aplikacja SPU [jest skończona](/blog/2010/09/parcelscout-deplyment-i-profile-w-mavenie/) można zająć się kolejnym elementem
[infrastruktury ParcelScout](/blog/2010/08/parcelscout-zalodzenia-i-architektura/). Aby pozostać przy tematyce [Spring-owej](http://www.springsource.org/)
postanowiłem zaimplementować serwis ParcelScout oparty właśnie o Spring MVC.

## Architektura systemu ParcelScout

Architektura systemu ParcelScout przedstawiona została na poniższym diagramie:

{% assign i_src='parcel-scout/parcelscout_spring_components_diagram.png' %}
{% assign i_title='Diagram komponentów aplikacji ParcelScout' %}
{% include image.html %}

Ponieważ docelowo serwisów lokalizacji paczek będzie wiele wydzieliłem logikę integracji z aplikacją SPU jako osobny moduł. Logika ta realizowana będzie
za pośrednictwem interfejsu ``PackagePositionResolver``. Dodatkowo wydzieliłem moduł ``Core``, który odpowiedzialny będzie za dostarczanie wszelkich
narzędzi dla modułów integracyjnych.

### Struktura aplikacji

Moją osobistą preferencją jest implementowanie modułów jako osobnych projektów (tak abym każdy moduł miał w osobnym archiwum). Niektórzy wolą wszystkie
moduły łączyć w jeden projekt, ale ja uważam, że wtedy robi się zbyt duży śmietnik (zwłaszcza w kontekście modelu, który dla każdego modułu integracyjnego
będzie się jakoś różnił).

Zatem postanowiłem aplikację utworzyć jako zbiór modułów maven'owych zgodnie ze strukturą:

<pre>
<span class="k">parcelscout-spring/</span>
    pom.xml
    <span class="k">parcelscout-webapp/</span>
        pom.xml
        <span class="k">src/</span>
            <span class="k">main/</span>
                <span class="k">resources/</span>
                    logback.xml
                    import.sql
                <span class="k">webapp/</span>
                    <span class="k">WEB-INF/</span>
                        package-servlet.xml
                        web.xml
    <span class="k">parcelscout-core/</span>
        pom.xml
        <span class="k">src/</span>
            <span class="k">main/</span>
                <span class="k">java/</span>
                    *.java
    <span class="k">parcelscout-spu-integration/</span>
        pom.xml
        <span class="k">src/</span>
            <span class="k">main/</span>
                <span class="k">java/</span>
                    *.java
</pre>

Nie będę się rozpisywał w jaki sposób w mavenie utworzyć taką strukturę, oraz jakie są zależności (to akurat można obejrzeć w kodzie).
Przejdę od razu do tego co najciekawsze, czyli implementacji.

## Implementacja serwisu

Pierwszym elementem jest kontroler, który w przypadku serwisu ParcelScout będzie odbierał żądania, na podstawie parametrów będzie określał
jaki moduł integracyjny powinien zająć się faktycznym ustaleniem pozycji paczki, delegował zadanie zlokalizowania paczki do określonego modułu,
 a następnie przygotowywał model do wyrenderowania odpowiedzi.
Dla ułatwienia przyjąłem sobie, że żądanie będzie posiadać parametr ``carrierId`` określający dostawcę paczki, jednakże w przypadku prawdziwej
aplikacji ta operacja mogła by być nieco bardziej skomplikowana (identyfikatory paczek mogły by mieć jakiś prefiks, albo unikalny format itp.).
Kod kontrolera przedstawia się następująco:

{% highlight java %}
@Controller
@RequestMapping("/packageSearch")
public class PackageController {
    @Autowired
    private PackagePositionResolverFactory packagePositionResolverFactory;

    @RequestMapping(method = RequestMethod.GET)
    public void resolvePackagePosition(@RequestParam String carrierId, @RequestParam Integer packageId, Model model) {
        PackagePositionResolver resolver = packagePositionResolverFactory.createPackagePositionResolver(carrierId);
        ResultSet result = resolver.resolvePackagePosition(packageId);
        model.addAttribute("ResultSet", result);
    }

}
{% endhighlight %}

Aplikacja opiera się o konfigurację analogiczną do tej z aplikacji SPU. Kontroler mapuje żądania ``/packageSearch``, na podstawie
parametru ``carrierId`` określa moduł integracyjny do którego deleguje zadanie zwrócenia pozycji, a następnie wynik dodaje do modelu
celem wyrenderowania na widoku (jako XML lub JSON w zależności od rozszerzenia albo parametru ``Accept`` nagłówka HTTP).

Faktyczną operacją określenia modułu integracyjnego zajmie się obiekt ``PackagePositionResolverFactory``:

{% highlight java %}
public class PackagePositionResolverFactory {
    private Map<String, PackagePositionResolver> resolvers;

    public PackagePositionResolver createPackagePositionResolver(String carrierId) {
        PackagePositionResolver resolver = resolvers.get(carrierId);
        return resolver;
    }

    public void setResolvers(Map<String, PackagePositionResolver> resolvers) {
        this.resolvers = resolvers;
    }
}
{% endhighlight %}

Komponent ten wykorzystuje zwyczajną mapę do pobrania odpowiedniej implementacji. Mapa ta, jak i sam komponent, deklarowana jest
w Spring'owym pliku konfiguracyjnym, dzięki czemu aplikacja zyskała deklaratywną swobodę w wymianie, jak i dodawaniu nowych modułów.
Konfiguracja wyglądać będzie następująco:

{% highlight xml %}
<bean id="packagePositionResolverFactory"
      class="pl.michalorman.parcelscout.core.factory.PackagePositionResolverFactory">
    <property name="resolvers">
        ...
    </property>
</bean>
{% endhighlight %}

Jeżeli chcemy dodać nowy (albo zmienić) moduł integracyjny wystarczy dorzucić do aplikacji dodatkowe archiwum JAR i dopisać
odpowiednią deklarację do konfiguracji komponentu ``packagePositionResolverFactory``.

### ``PackagePositionResolver`` dla SPU

Faktycznym pobraniem pozycji paczki zajmuje się obiekt implementujący interfejs ``PackagePositionResolver``:

{% highlight java %}
public interface PackagePositionResolver {
    public ResultSet resolvePackagePosition(Integer packageId);
}
{% endhighlight %}

Interfejs ten deklaruje jedną metodę, która na podstawie zadanego identyfikatora paczki zwraca obiekt ``ResultSet``, który następnie
jest dodawany do modelu celem wyrenderowania.

Teraz najważniejsza rzecz, czyli moduł komunikujący się z serwisem SPU. Aplikacja SPU pozwala na
[negocjowanie formatu odpowiedzi](/blog/2010/09/parcelscout-negocjowanie-formatu-odpowiedzi-w-aplikacji-spu/). Do wyboru mamy formaty
JSON albo XML. W przypadku aplikacji SPU skorzystałem z frameworków [XStream](http://xstream.codehaus.org/) oraz [Jackson](http://jackson.codehaus.org/)
do serializowania obiektów odpowiednio do formatu XML i JSON. W przypadku tego modułu postanowiłem zamienić XStream'a na [JAXB](http://www.oracle.com/technetwork/articles/javase/index-140168.html)
(planuję jeszcze napisanie wersji wykorzystującej framework [JiBX](http://jibx.sourceforge.net/)).

W pierwszej kolejności należy utworzyć odpowiedni model, który powinien odpowiadać strukturze odpowiedzi otrzymanej z aplikacji SPU.

{% highlight java %}
@XmlRootElement
@XmlAccessorType(XmlAccessType.FIELD)
public class Response {
    @XmlAttribute
    private String status;

    @XmlElement(name = "package")
    private Package parcel;

    public boolean isSuccessful() {
        return "101".equals(status);
    }
}
{% endhighlight %}

{% highlight java %}
public class Package {
    @XmlAttribute
    private Integer id;

    @XmlElement
    private Position position;
}
{% endhighlight %}

{% highlight java %}
public class Position {
    @XmlAttribute
    private double latitude;

    @XmlAttribute
    private double longitude;
}
{% endhighlight %}

To co w parsowanym XML-u jest elementem oznaczamy adnotacją ``@XmlElement`` natomiast to co atrybutem ``@XmlAttribute``.
Wykorzystując argument ``name`` tych adnotacji, możemy określić na jaką nazwę elementu, bądź atrybutu mapowane jest pole klasy.

Mając model możemy utworzyć właściwy komponent:

{% highlight java %}
public class SpuServicePackagePositionResolver implements PackagePositionResolver {
    private String serviceUrl;

    @Autowired
    private RestTemplate restTemplate;

    @Override
    public ResultSet resolvePackagePosition(Integer packageId) {
        Response response = restTemplate.getForObject(serviceUrl + "?packageId={packageId}", Response.class, packageId);
        if (!response.isSuccessful()) {
            return ResultSet.createFailureResultSet();
        }
        return ResultSet.createSuccessfulResultSet(response.getPackageId(), response.getPackageLatitude(), response.getPackageLongitude());
    }
}
{% endhighlight %}

W Spring MVC wysłanie żądania do zdalnego serwisu, a następnie sparsowanie odpowiedzi i zwrócenie jej w formie odpowiedniego
obiektu modelu sprowadza się do wywołania jednej metody na obiekcie ``RestTemplate``. Metoda ``getForObject()`` wyśle nam żądanie HTTP GET
pod wskazany adres URL, następnie przetworzy odpowiedź i zwróci nam odpowiedni obiekt.

Aby wszystko działało jak należy musimy zadeklarować obiekt ``RestTemplate``, który potem będzie wstrzykiwany do komponentu
``SpuServicePackagePositionResolver``:

{% highlight xml %}
<bean id="jaxbMarshaller" class="org.springframework.oxm.jaxb.Jaxb2Marshaller">
    <property name="classesToBeBound">
        <list>
            <value>pl.michalorman.parcelscout.core.api.ResultSet</value>
            <value>pl.michalorman.parcelscout.integration.spu.model.Response</value>
        </list>
    </property>
</bean>

<bean id="restTemplate" class="org.springframework.web.client.RestTemplate">
    <property name="messageConverters">
        <list>
            <bean class="org.springframework.http.converter.json.MappingJacksonHttpMessageConverter" />
            <bean class="org.springframework.http.converter.xml.MarshallingHttpMessageConverter">
                <constructor-arg ref="jaxbMarshaller" />
            </bean>
        </list>
    </property>
</bean>
{% endhighlight %}

Komponent ``restTemplate`` posiada pole ``messageConverters``, które określa listę obiektów typu ``HttpMessageConverter``, które są odpowiedzialne
za odczytanie odpowiedzi HTTP i mapowanie jej na odpowiednie obiekty. W powyższej konfiguracji deklaruję dwa takie komponenty, po jednym
dla formatu XML i JSON.

Teraz pozostało już tylko spięcie komponentu z fabryką:

{% highlight xml %}
<bean id="packagePositionResolverFactory"
      class="pl.michalorman.parcelscout.core.factory.PackagePositionResolverFactory">
    <property name="resolvers">
        <map>
            <entry key="SPU">
                <bean class="pl.michalorman.parcelscout.integration.spu.service.SpuServicePackagePositionResolver">
                    <property name="serviceUrl" value="http://localhost:8100/track.xml"/>
                </bean>
            </entry>
        </map>
    </property>
</bean>
{% endhighlight %}

Wykorzystując rozszerzenie w konfiguracji pola ``serviceUrl`` możemy deklarować, czy nasz interfejs ma komunikować się z wykorzystaniem
formatu XML czy JSON. Niestety w obecnej implementacji klasy ``RestTemplate`` nie ma prostego sposobu konfigurowania nagłówków żądania
HTTP (a w szczególności pola ``Accept``). Są na to jakieś obejścia, ale w moim przypadku nie działały. Jest to [znany](https://jira.springframework.org/browse/SPR-5866)
problem i w kolejnym wydaniu Spring MVC ma zostać dodany odpowiedni mechanizm [interceptorów](https://jira.springsource.org/browse/SPR-7494), specjalnie
do tego celu. Na razie pozostaje nam tylko manipulowanie rozszerzeniem (o ile nie chcemy tworzyć jakiś *custom-modyfikacji* klasy ``RestTemplate``).

### Dodanie wsparcia formatu JSON

W tej chwili nasz moduł potrafi komunikować się z aplikacją SPU wykorzystując format XML. Aby dodać wsparcie dla formatu JSON musimy nanieść
pewne modyfikacje na nasz model:

{% highlight java %}
@XmlRootElement
@XmlAccessorType(XmlAccessType.FIELD)
public class Response {

    @XmlAttribute
    @JsonProperty("status")
    private String status;

    @XmlElement(name = "package")
    @JsonProperty("package")
    private Package parcel;
}
{% endhighlight %}

{% highlight java %}
public class Package {

    @XmlAttribute
    @JsonProperty("id")
    private Integer id;

    @XmlElement
    @JsonProperty("position")
    private Position position;
}
{% endhighlight %}

{% highlight java %}
public class Position {

    @XmlAttribute
    @JsonProperty("latitude")
    private double latitude;

    @XmlAttribute
    @JsonProperty("longitude")
    private double longitude;
}
{% endhighlight %}

Wszystkie pola musimy oznaczyć adnotacją ``@JsonProperty``. Szczerze powiedziawszy nie rozumiem tego, ponieważ framework mógłby spokojnie
z pomocą refleksji mapować elementy odpowiedzi z odpowiednimi polami klasy. Natomiast gdyby zaszła potrzeba zmiany nazwy elementu, czy
zaznaczenie w jakiś sposób, że dane pole nie występuje w dokumencie JSON to wtedy powinno się nakładać adnotacje (zgodnie z zasadą
configuration by exception). No, cóż widać twórcy frameworka zdecydowali inaczej (albo ja coś zchrzaniłem w konfiguracji :P).

### Wykorzystanie adnotacji JAXB zamiast adnotacji Jackson'a

Posiadanie jednocześnie adnotacji JAXB jak i Jackson'a trochę zaśmieca kod, jednakże przy odrobinie dodatkowej pracy możemy skonfigurować
Jackson'a w taki sposób, aby [korzystał z adnotacji JAXB](http://wiki.fasterxml.com/JacksonJAXBAnnotations). W tym celu musimy dodać zależność
do biblioteki ``jackson-xc``:

{% highlight xml %}
<dependency>
    <groupId>org.codehaus.jackson</groupId>
    <artifactId>jackson-xc</artifactId>
    <version>${org.codehaus.jackson.version}</version>
</dependency>
{% endhighlight %}

Następnie musimy rozszerzyć klasę ``ObjectMapper``, aby korzystała z adnotacji JAXB:

{% highlight java %}
public class JaxbJacksonObjectMapper extends ObjectMapper {
    public JaxbJacksonObjectMapper() {
        super();
        getDeserializationConfig().setAnnotationIntrospector(new JaxbAnnotationIntrospector());
    }
}
{% endhighlight %}

Na końcu wystarczy odpowiednio zmienić konfigurację komponentu Spring'owego, dodając ustawienie pola ``objectMapper``:

{% highlight xml %}
<bean id="restTemplate" class="org.springframework.web.client.RestTemplate">
    <property name="messageConverters">
        <list>
            <bean class="org.springframework.http.converter.json.MappingJacksonHttpMessageConverter">
                <property name="objectMapper">
                    <bean class="pl.michalorman.springframework.web.json.JaxbJacksonObjectMapper" />
                </property>
            </bean>
            ...
        </list>
    </property>
</bean>
{% endhighlight %}

Teraz możemy usunąć z modelu adnotacje Jacksona i pozostawić tylko JAXB. Swoją drogą można by pomyśleć o jakimś API do serializacji obiektów,
pozwalającym na nałożenie ogólnych adnotacji i serializowanie obiektu do wybranych formatów.

## Podsumowanie

Implementacja aplikacji ParcelScout, która integruje świat WWW z serwisem SPU nie była tak trudna, dzięki wykorzystaniu frameworka Spring MVC.
Klasa ``RestTemplate`` sprowadziła cały proces komunikacji między aplikacjami do wywołania jednej metody i, pomimo braku w chwili obecnej
możliwości łatwego definiowania parametrów nagłówka HTTP, jest ona bardzo użyteczna. Serwis, podobnie jak aplikacja SPU, posiada zaimplementowaną
funkcjonalność negocjowania formatu odpowiedzi, oraz deklaratywną możliwość zmiany formatu komunikacji z aplikacją SPU. Przy niewielkim wysiłku
dało się też skonfigurować komponent mapujący odpowiedź w formacie JSON w taki sposób, aby korzystał z adnotacji JAXB, co oczyściło nasz model
ze zbędnych adnotacji.

Cała architektura aplikacji ParcelScout jest modułowa. Dodanie kolejnego komponentu określającego pozycję paczki sprowadza się do dodania
do aplikacji dodatkowego archiwum JAR, oraz zadeklarowania odpowiedniego komponentu w Spring'owym pliku konfiguracyjnym. Podział aplikacji
na moduły jest wyłącznie moją, specyficzną preferencją, równie dobrze można by zaimplementować ją jako jeden wielki worek z wszystkimi
potrzebnymi modułami.

Kod aplikacji ParcelScout (w wersji korzystającej z frameworka Spring MVC) dostępny jest pod adresem:
[http://github.com/michalorman/parcelscout/tree/master/work/parcelscout-spring/](http://github.com/michalorman/parcelscout/tree/master/work/parcelscout-spring/)
