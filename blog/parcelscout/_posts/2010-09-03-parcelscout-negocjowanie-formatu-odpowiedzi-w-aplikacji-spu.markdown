---
layout: post
title: ParcelScout - negocjowanie formatu odpowiedzi w aplikacji SPU
description: Opis konfiguracji mechanizmu negocjowania formatu odpowiedzi w Spring MVC.
keywords: Spring MVC JSON XML application Accept Conent-Type HTTP
---
W obecnej formie aplikacja SPU potrafi wysyłać odpowiedzi w formacie XML lub JSON. Oto jak przedstawia się kontroler tej aplikacji:

{% highlight java %}
@Controller
public class PackageController {
    private Logger logger = LoggerFactory.getLogger(PackageController.class);

    @Autowired
    private PackageTrackService parcelService;

    @RequestMapping(value = "/track.xml", method = RequestMethod.GET)
    public String getPackagePositionInXml(@RequestParam Integer packageId, Model model) {
        logger.info("Received request for /track.xml with params: packageId='{}'", packageId);
        addPackageToModel(packageId, model);
        return "responseXmlView";
    }

    @RequestMapping(value = "/track.json", method = RequestMethod.GET)
    public String getPackagePositionInJson(@RequestParam Integer packageId, Model model) {
        logger.info("Received request for /track.json with params: packageId='{}'", packageId);
        addPackageToModel(packageId, model);
        return "responseJsonView";
    }

    @RequestMapping(value = "/track", method = RequestMethod.GET, headers = "content-type=application/xml")
    public String trackPackagePositionInXml(@RequestParam Integer packageId, Model model) {
        logger.info("Received request for /track with content-type=application/xml and params: packageId='{}'",
                packageId);
        addPackageToModel(packageId, model);
        return "responseXmlView";
    }

    @RequestMapping(value = "/track", method = RequestMethod.GET, headers = "content-type=application/json")
    public String trackPackagePositionInJson(@RequestParam Integer packageId, Model model) {
        logger.info("Received request for /track with content-type=application/json and params: packageId='{}'",
                packageId);
        addPackageToModel(packageId, model);
        return "responseJsonView";
    }

    private void addPackageToModel(Integer packageId, Model model) {
        TrackResponse response = parcelService.getTrackInfo(packageId);
        model.addAttribute("response", response);
    }

}
{% endhighlight %}

Jest kilka problemów związanych z tą implementacją. Zauważmy, że wszystkie metody odpowiedzialne za obsługę żądania (czyli te oznaczone adnotacją ``@RequestMapping``)
robią zasadniczo to samo. Różnica jest tylko w zwracanej wartości (która odpowiada nazwie komponentu widoku odpowiedzialnego za wyrenderowanie odpowiedzi). Nie jest
to specjalnie dobre rozwiązanie (zgodnie z zasadą [DRY](http://pl.wikipedia.org/wiki/DRY)). Dodanie obsługi nowego formatu (np. ``application/pdf``) wymagałoby dodania
kolejnej metody, która w ten sam sposób przygotowywałaby model i zwracała inną nazwę widoku.

Inny problem, już bardziej techniczny niż projektowy, to to, że mapowanie nie powinno być na parametr nagłówka ``Content-Type`` a ``Accept``. Parametr ``Content-Type``
służy do poinformowania serwera w jakim formacie są dane przesyłane żądaniem POST lub PUT, natomiast to parametr ``Accept`` określa w jakim formacie oczekujemy
odpowiedzi. O ile ten błąd można szybko naprawić, o tyle poprzedni wymagać będzie trochę więcej pracy.

## Negocjowanie formatu odpowiedzi w Spring MVC

Framework Spring MVC udostępnia nam klasę ``ContentNegotiatingViewResolver``, która wybiera na podstawie rozszerzenia lub parametru ``Accept`` (nagłówka HTTP) komponent
widoku, jaki ma wyrenderować odpowiedź. Jeżeli w naszej aplikacji używamy jeszcze innych komponentów ``ViewResolver`` to musimy zadbać, aby komponent
``ContentNegotiatingViewResolver`` był skonfigurowany jako pierwszy do uruchomienia (każdy resolver posiada atrybut ``order``, po szczegóły odsyłam do dokumentacji).
W takiej sytuacji obiekt ``ContentNegotiatingViewResolver`` nie będzie delegował do obiektu widoku, a do innego resolvera, który potrafi wygenerować odpowiedź
w żądanym formacie.

Komponent ``ContentNegotiatingViewResolver`` tak naprawdę mapuje rozszerzenia na odpowiadający typ MIME. Dodatkowo wyciąga typ MIME z parametru ``Accept`` nagłówka HTTP.
Z takim typem MIME iteruje po wszystkich widokach albo obiektach typu ``ViewResolver`` i szuka tego, który obsługuje dany format (każdy obiekt widoku posiada
przypisany typ MIME jaki obsługuje). Kiedy znajdzie pasujący to deleguje do niego zadanie wyrenderowania widoku (a jak nie znajdzie to rzuca nam wyjątkiem prosto w
twarz). Ot i cała tajemnica działania tego komponentu. Dodajmy zatem funkcjonalność negocjowania formatu do aplikacji SPU.

## Negocjowanie formatu odpowiedzi w aplikacji SPU

W aplikacji SPU nie ma sensu istnienie wielu obiektów ``ViewResolver``. Obecnie skonfigurowany jest tylko jeden ``BeanNameViewResolver``, który dobiera widok po
nazwie. W obecnej sytuacji nie potrzebujemy ani tego resolvera, ani w ogóle nazw widoków, ponieważ komponent renderujący widok dobierany będzie na podstawie typu
MIME. Zobaczmy jak drastycznie uprościło to kod kontrolera:

{% highlight java %}
@Controller
public class PackageController {
    private Logger logger = LoggerFactory.getLogger(PackageController.class);

    @Autowired
    private PackageTrackService parcelService;

    @RequestMapping(value = "/track", method = RequestMethod.GET)
    public void getPackageTrackInfo(@RequestParam Integer packageId, Model model) {
        logger.info("Get track info for package: '{}'", packageId);
        TrackResponse response = parcelService.getTrackInfo(packageId);
        model.addAttribute("response", response);
    }
}
{% endhighlight %}

W tej wersji kontroler posiada tylko jedną metodę mapowaną na ``/track``, której jedynym zadaniem jest przygotowanie danych modelu. Zwróćmy uwagę, że metoda ta
nie zwraca (jak w poprzedniej wersji) nazwy widoku do wyrenderowania, ani w żaden inny sposób nie informuje jakiego widoku użyć (a mogła by to zrobić np. używając
klasy ``ModelAndView``).

Wybraniem komponentu widoku do wyrenderowania odpowiedzi, jak wcześniej wspomniałem, zajmie się komponent ``ContentNegotiatingViewResolver``. Zatem należy go
zdefiniować w pliku ``track-servlet.xml``:

{% highlight xml %}
<bean id="contentNegotiationResolver" class="org.springframework.web.servlet.view.ContentNegotiatingViewResolver">
    <property name="mediaTypes">
        <map>
            <entry key="xml" value="application/xml" />
            <entry key="json" value="application/json" />
        </map>
    </property>
    <property name="defaultViews">
        <list>
            <bean class="org.springframework.web.servlet.view.json.MappingJacksonJsonView" />
            <bean class="org.springframework.web.servlet.view.xml.MarshallingView">
                <constructor-arg>
                    <bean class="org.springframework.oxm.xstream.XStreamMarshaller">
                        <property name="autodetectAnnotations" value="true" />
                    </bean>
                </constructor-arg>
            </bean>
        </list>
    </property>
</bean>
{% endhighlight %}

W komponencie ustawiamy dwa atrybuty: ``mediaType`` mapujące rozszerzenia na typy MIME, oraz ``defaultViews`` jako listę komponentów widoku, które będą
renderować odpowiedź dla obsługiwanego typu MIME. To z listy widoków skonfigurowanej jako ``defaultViews`` komponent będzie wyszukiwał tego widoku, który obsługuje
dany typ MIME.

Teraz można przetestować aplikację świeżo co utworzonymi [testami integracyjnymi](/blog/2010/09/parcelscout-testy-integracyjne-aplikacji-spu/) (wcześniej
trzeba poprawić klasę bazową, aby zamiast parametru ``Content-Type`` ustawiała parametr ``Accept``).

## Dodanie odpowiedzi w formacie YAML

Aby sprawdzić, czy faktycznie łatwo i deklaratywnie można dodać kolejny format odpowiedzi, spróbuję dodać obsługę formatu serializacji danych [YAML](http://en.wikipedia.org/wiki/YAML).
Ponieważ standardowo w Springu nie ma klasy widoku renderującej odpowiedź w tym formacie napiszę ją sam:

{% highlight java %}
public class SnakeYAMLView extends AbstractView {
    public static final String DEFAULT_CONTENT_TYPE = "application/x-yaml";

    public SnakeYAMLView() {
        setContentType(DEFAULT_CONTENT_TYPE);
    }

    @Override
    protected void renderMergedOutputModel(Map<String, Object> model, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        Map<String, Object> filteredModel = filterModel(model);
        StringBuilder builder = new StringBuilder();
        Yaml yaml = new Yaml();
        yaml.setBeanAccess(BeanAccess.FIELD);

        for (Map.Entry<String, Object> entry : filteredModel.entrySet()) {
            builder.append(String.format("%s\n", yaml.dump(entry.getValue())));
        }

        response.getOutputStream().print(builder.toString());
    }

    private Map<String, Object> filterModel(Map<String, Object> model) {
        Map<String, Object> result = new HashMap<String, Object>();
        for (Map.Entry<String, Object> entry : model.entrySet()) {
            Object value = entry.getValue();
            String key = entry.getKey();

            if (!(value instanceof BindingResult) && !(value instanceof BeanPropertyBindingResult)) {
                result.put(key, value);
            }
        }
        return result;
    }
}
{% endhighlight %}

W konstruktorze ustawiam format obsługiwany przez tę klasę na ``application/x-yaml``. Do wyrenderowania odpowiedzi (w metodzie ``renderMergedOutputModel``) użyłem narzędzia
[``SnakeYAML``](http://code.google.com/p/snakeyaml/). Metoda ``filterModel`` usuwa z mapy modelu niepotrzebne obiekty (których nie chcemy w wyrenderowanej odpowiedzi).

Mając klasę widoku, możemy dodać ją do konfiguracji obiektu ``ContentNegotiatingViewResolver``:

{% highlight xml %}
<bean id="contentNegotiationResolver" class="org.springframework.web.servlet.view.ContentNegotiatingViewResolver">
    <property name="mediaTypes">
        <map>
            <entry key="xml" value="application/xml" />
            <entry key="json" value="application/json" />
            <entry key="yaml" value="application/x-yaml" />
        </map>
    </property>
    <property name="defaultViews">
        <list>
            <bean class="org.springframework.web.servlet.view.json.MappingJacksonJsonView" />
            <bean class="org.springframework.web.servlet.view.xml.MarshallingView">
                <constructor-arg>
                    <bean class="org.springframework.oxm.xstream.XStreamMarshaller">
                        <property name="autodetectAnnotations" value="true" />
                    </bean>
                </constructor-arg>
            </bean>
            <bean class="pl.michalorman.springframework.web.servlet.view.yaml.SnakeYAMLView" />
        </list>
    </property>
</bean>
{% endhighlight %}

No to generalnie wszystko. Uruchamiamy serwer za pomocą komendy ``mvn jetty:run`` i testujemy:

{% highlight bash %}
$ curl http://localhost:8080/spu-service/track.yaml?packageId=5
!!pl.michalorman.spu.api.TrackResponse
parcel:
  id: 5
  position: {latitude: 49.57, longitude: 18.43}
status: 101
{% endhighlight %}

Działa!

## Podsumowanie

Wcześniejsza implementacja negocjowania formatu była zła. Pomijając już błąd z parametrem nagłówka HTTP to implementacja nie była odporna na modyfikacje, a te same
czynności były powtarzane w wielu metodach kontrolera. Dzięki klasie ``ContentNegotiatingViewResolver`` udało się skonfigurować mechanizm negocjowania formatu do tego
stopnia, że kontroler przygotowuje jedynie model do wyrenderowania a obiekt ``ContentNegotiatingViewResolver`` zajmuje się określeniem jaki komponent widoku powinien
zająć się wyrenderowaniem odpowiedzi. To podejście nie tylko znacznie uprościło kod kontrolera, ale pozwoliło w deklaratywny sposób dodawać nowe formaty odpowiedzi,
co uwidoczniłem na przykładzie dodania formatu YAML.

Jak zawsze kod do wglądu na moim profilu GitHub: [http://github.com/michalorman/parcelscout/tree/master/work/spu-service/](http://github.com/michalorman/parcelscout/tree/master/work/spu-service/).
