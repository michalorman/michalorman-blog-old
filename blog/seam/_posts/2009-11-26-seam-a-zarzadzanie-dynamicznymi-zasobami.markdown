---
layout: post
title: Seam a zarządzanie dynamicznymi zasobami
description: O tym jak źle zaimplementowane jest zarządzanie zasobami w frameworku Seam i dlaczego należy omijać je z daleka
keywords: Seam Framework Komponent Obrazek BLOB SeamResourceServlet Servlet web.xml Mapping
---
Wyobraźmy sobie taki scenariusz. Jesteśmy na portalu, wchodzimy na profil jakiegoś użytkownika lub na szczegóły jakiejś oferty. Przeglądamy obrazki, w niektóre klikamy bo chcemy zobaczyć je w oryginalnym rozmiarze a na niektórych klikamy prawym klawiszem myszki bo chcemy zapisać na dysku. Scenariusz niezbyt wyrafinowany. Tak oczywisty przypadek użycia, że w XXI wieku, w dobie wszechobecnego Ajaxu i aplikacji RIA niemożliwe jest aby jakikolwiek system nie udostępniał takiej funkcjonalności. Ba, nie do pomyślenia jest, aby jakaś platforma nie udostępniała takiej funkcjonalności out of box. Nie po raz pierwszy przekonałem się, że platforma JEE to dziwna platforma...

Zobaczmy jakie możliwości daje nam jeden z najpopularniejszych ostatnio frameworków, czyli <a href="http://seamframework.org/">Seam</a>. Weźmy na tapetę sytuację, gdy zasoby przechowywane są w bazie (aby nie musieć ich synchronizować między nodami) i serwowane są dynamicznie. Upload jest w Seamie trywialny. Wystarczy nam zwykła encja mapująca BLOB-a:

{% highlight java %}
@Entity
public class Image {
    @Lob @Column(name = "data"), @Basic(fetch = FetchType.LAZY)
    private byte[] data;
}
{% endhighlight %}

Jeżeli nie potrzebujemy żadnych fikuśnych komponentów pozwalających na upload wielu plików naraz wystarczy nam zwykły Seam'owy komponent `<s:fileUpload />`.

{% highlight xml %}
<s:fileUpload accept="image/jpg" data="#{action.data}" contentType="#{action.contentType}" />
{% endhighlight %}

Gdzie w komponencie `action` mapujemy pole `data` na typ `byte[]` oraz pole `contentType` na `String`. Przepisujemy dane do encji, persystujemy i wszystko gra. No dobra, ale teraz chcielibyśmy odczytać to co zapisaliśmy. Seam ma nam do zaoferowania specjalny <a href="http://en.wikipedia.org/wiki/Java_Servlet">Servlet</a>. Aby móc skorzystać z owego servleta (a może servletu?) należy, jak każdy servlet, skonfigurować go w pliku `WEB-INF/web.xml`:

{% highlight xml %}
<servlet>
    <servlet-name>Seam Resource Servlet</servlet-name>
    <servlet-class>org.jboss.seam.servlet.SeamResourceServlet</servlet-class>
</servlet>

<servlet-mapping>
    <servlet-name>Seam Resource Servlet</servlet-name>
    <url-pattern>/seam/resource/*</url-pattern>
</servlet-mapping>
{% endhighlight %}

Tutaj pojawia się już pierwszy problem. Powyższa konfiguracja musi zostać ustawiona dokładnie jak powyżej, wszelkie modyfikacje np. URL-a dla mapingu spełzną na niczym, gdyż w kodzie Seama ścieżka /seam/resource jest zahardkodowana (czyli wpisana na sztywno w kodzie)! Nie jest to z resztą jedyny hardcode w tym frameworku. Także jesteśmy uwiązani do tego mapingu i tyle. No dobra, ale to tylko dynamiczny content, jakoś to przeżyjemy, byleby wyświetlić nasz upragniony obrazek, który wcześniej załadowaliśmy do bazy. Wrzućmy go wreszcie na view!

Tutaj Seam znów przychodzi nam z pomocą (chociaż zamiast ratunkowego koła podaje nam raczej kowadło, ale nie uprzedzajmy faktów). Standardowy komponent JSF służący do wyświetlania obrazków, czyli <h:graphicImage /> nie wyświetli nam dynamicznej zawartości, ale za to jego Seam'owy odpowiednik <s:graphicImage /> już tak:

{% highlight html %}
<s:graphicImage value="#{image}" />
{% endhighlight %}

Wystarczy, że pod atrybut `value` (czyli to co znajduje się pod zmienną kontekstową `image` w tym przykładzie) damy ciąg bajtów w postaci tablicy (`byte[]`), czyli dokładnie to co zamapowaliśmy w encji i zapisaliśmy w bazie, i będziemy raczyć się pięknym widokiem naszego obrazka. Tak więc sprawa jest trywialna, ściągamy encję `Image` z bazy, wystrzliwujemy pod zmienną kontekstową `image` zawartość pola `data` i niczym się nie martwimy, servlet automatycznie ustawi odpowiedni content-type itp. Standardowo komponent ten nadaje losową nazwę (dziwną z resztą), jeżeli chcemy to zmienić to dorzucamy atrybut `fileName` i po sprawie. No miodzio, łatwizna wszystko się praktycznie robi samo. To zobaczmy sobie teraz podgląd obrazka, klikamy prawym klawiszem myszki, na naszym upragnionym obrazku, wybieramy opcję "Pokaż obrazek" w naszym najnowszym Firefox-ie (czy innej Operze) i...

<a href="/images/jboss_404.png" rel="colorbox"><img title="jboss-404" src="/images/jboss_404.png" alt="404" width="830" height="175" /></a>

Nie no głupie IDE/serwer aplikacji na pewno coś źle zdeployowało, zrestartujmy - to zawsze pomaga! Niestety próbujesz dalej a tu ciągle 404, dla pewności restartujesz kompa, ale obrazek jak nie chciał się wyświetlić tak dalej nie chce! Ale dlaczego? Przecież zrobiliśmy wszystko jak <a href="http://docs.jboss.com/seam/latest/reference/en-US/html/index.html">dokumentacja</a> i <a href="http://www.manning.com/dallen/">Seam in Action</a> każą! Co jest!?

Zanim zaczniesz obijać pięściami klawiaturę albo rzucać laptopem z okna przeczytaj ten wpis do końca. Osoby, które pisały specyfikację czy książki o Seamie skrzętnie zataiły pewne fakty, gdzie Seam po prostu nie działa. Poszukaj i w dokumentacji i w książkach, a nawet i w google jak w Seamie pobierać dynamiczny content. Gwarantuje ci, że nie nic znajdziesz, gdyż Seam po prostu ma to skaszanione. Jeżeli zastanawiasz się, dlaczego obrazek pojawił się w na view, ale próba jego podglądnięcia daje 404 wiedz, że nie jesteś pierwszy. Ja już to przerobiłem i oszczędzę ci czasu dając odpowiedź jak to się mianowicie dzieje.

### To o czym autorzy Seam'a zapomnieli wspomnieć

Pamiętaj, że framework ten robią developerzy tacy jak my. Wśród nich zdarzają się lepsi i gorsi i tak jak my mogą po prostu zrobić w kodzie kiche (ale gorzej już, gdy taką skaszanioną rzecz reklamuje się jako super funkcjonalność - to już jest bardzo brzydko!). A więc do rzeczy. Sytuacja jest taka, wchodzimy na widok i mamy obrazek, jednak gdy chcemy zrobić podgląd otrzymujemy 404. Wiemy też, że za obsługę zasobów odpowiada `SeamResourceServlet` dlatego od niego zaczynamy nasze poszukiwania. Obsługa żądania odbywa się w metodzie `service` tejże klasy. W metodzie tej w zależności od URL-a wybierany jest odpowiedni provider, który wykonuje faktyczną operację pobrania zasobu. Dokładnie wspomniany fragment kodu wygląda tak:

{% highlight java %}
@Override
public void service(HttpServletRequest request, HttpServletResponse response)
         throws ServletException, IOException
{
   String prefix = request.getContextPath() + request.getServletPath();

   if (request.getRequestURI().startsWith(prefix))
   {
      String path = request.getRequestURI().replaceFirst(prefix, "");
      int index = path.indexOf('/', 1);
      if (index != -1) path = path.substring(0, index);

      AbstractResource provider = providers.get(path);
      if (provider != null)
      {
         provider.getResource(request, response);
      }
      else
      {
         response.sendError(HttpServletResponse.SC_NOT_FOUND);
      }
   }
   else
   {
      response.sendError(HttpServletResponse.SC_NOT_FOUND);
   }
}
{% endhighlight %}

To co faktycznie dzieje się w tej metodzie to wyznaczenie ścieżki zasobu o który nam chodzi poprzez odcięcie z URI części kontekstowej i mapingu servletowego. Później wybierany jest fragment, który odpowiada kluczowi w mapie `providers`, która to zwraca konkretnego providera danego zasobu. Jak widać, provider musi rozszeżać klasę `AbstractResource`. Zatem pytanie, który provider będzie obsługiwał nasze żądanie? Można go łatwo znaleźć sprawdzając w IDE jakie klasy rozszerzają klasę `AbstractResource`, ale my pójdziemy trochę dłuższą drogą. Przeanalizujmy co metoda `service` robi z naszym URI prowadzącym bezpośrednio do obrazka. Jeszcze raz klikamy prawym przyciskiem myszy na obrazku i dajemy podgląd, otrzymujemy 404, ale to co nas ciekawi to adres URL. Może on być na przykład taki:
<pre>http://localhost:8080/application/seam/resource/graphicImage/org.jboss.seam.ui.GraphicImageStore.208d951a-12531eb97a8--7fc1.png</pre>
Odcinamy z niego część kontekstową, czyli `http://localhost:8080/application` oraz servletową czyli `/seam/resource`, następnie do drugiego znaku '/' znajduje się nasz klucz do mapy providerów, czyli: `/graphicImage`. To pod tym kluczem znajduje się nasz provider. Przeszukując źródła (zwykłym przeszukiwaniem tekstowym) znajdujemy, że takiego klucza używa klasa `GraphicImageResource` (dokładnie jest to pole statyczne `RESOURCE_PATH`), przy okazji widzimy pięknego hardcoda:

{% highlight java %}
public static final String GRAPHIC_IMAGE_RESOURCE_PATH = "/seam/resource/graphicImage";
{% endhighlight %}

To między innymi dzięki niemu nie możemy zmienić ścieżki w pliku `web.xml`. W klasie `SeamResourceServlet` widzimy, że na rzecz providera wywoływana jest metoda `getResource` a więc jej należy się przyjrzeć w klasie `GraphicImageResource`. Metoda ta wywołuje metodę `doWork`, która wygląda następująco:

{% highlight java %}
private void doWork(HttpServletRequest request, HttpServletResponse response)
   throws IOException
{
  String pathInfo = request.getPathInfo().substring(getResourcePath().length() + 1,
            request.getPathInfo().lastIndexOf("."));
   ImageWrapper image = GraphicImageStore.instance().remove(pathInfo);
   if (image != null && image.getImage() != null)
   {
      response.setContentType(image.getContentType().getMimeType());
      response.setStatus(HttpServletResponse.SC_OK);
      response.setContentLength(image.getImage().length);
      ServletOutputStream os = response.getOutputStream();
      os.write(image.getImage());
      os.flush();
   }
   else
   {
      response.sendError(HttpServletResponse.SC_NOT_FOUND);
   }
}
{% endhighlight %}

Metoda ta wygrzebuje nazwę naszego pliku, który chcemy wyświetlić następnie wyciąga go z mapy znajdującej się w klasie `GraphicImageStore` opakowanego w `ImageWrapper` i jeżeli obrazek się tam znajduje przesyła go do przeglądarki w przeciwnym razie wysyła `HttpServletResponse.SC_NOT_FOUND`, czyli 404. Przyjrzyjmy się dokładniej linii 62:

{% highlight java %}
ImageWrapper image = GraphicImageStore.instance().remove(pathInfo);
{% endhighlight %}

Metoda ta wyciągając obrazek z `GraphicImageStore` od razu go usuwa, a więc jest on tam dostępny tylko przez 1 żądanie! I tu jest właśnie pies pogrzebany. Do tego bufora nasz obrazek wkłada komponent `<s:graphicImage />`  w momencie renderowania strony, jednakże próbując podglądnąć ten obrazek bezpośrednio nie wywołujemy cyklu JSF a więc nie ma kto nam tego obrazka wrzucić!

Sytuacja wygląda tak:
 
* Przeglądarka żąda strony. 
* Serwer ją renderuje a komponent `&lt;h:graphicImage /&gt;` umieszcza obrazek w mapie `GraphicImageStore`. 
* Serwer wysyła odpowiedź. 
* Przeglądarka parsuje wygenerowany HTML. 
* Przeglądarka napotyka na znacznik &lt;src&gt;, który odwołuje się do naszego obrazka. 
* Przeglądarka wysyła żądanie obrazka. 
* Serwer przekazuje kontrolę do servletu `SeamResourceServlet` a ten do klasy `GraphicImageResource` 
* Klasa `GraphicImageResource` wyciąga i usuwa nasz obrazek z `GraphicImageStore` 
* Serwer wysyła odpowiedź, przeglądarka odbiera i wyświetla obrazek. 
 
Teraz próbujemy wejść bezpośrednio po nasz obrazek:
 
* Przeglądarka wysyła żądanie. 
* Serwer przekazuje kontrolę do servletu SeamResourceServlet a ten do klasy `GraphicImageResource` 
* Klasa `GraphicImageResource` stwierdza, że obrazka nie ma w `GraphicImageStore` i wysyła kod błędu 404. 
 
Zróbcie taki eksperyment. Postawcie w eclipse breakpointa w klasie `GraphicImageStore` dokładnie w linii 62. Wyrenderujcie view z podglądem obrazka i czekajcie aż kontrola zatrzyma się w breakpoint-cie. Skopiujcie wartość zmiennej `pathInfo` do schowka i zmieńcie ją na cokolwiek innego następnie puśćcie aplikację (klawisz F8) i usuńcie breakpointa. Obrazek nie pojawi się, gdyż nie zostanie znaleziony w `GraphicImageStore`. Jeżeli teraz wygenerujecie żądanie bezpośrednio do obrazka (z odpowiednim mapingiem servletu i providera) doklejając to co skopiowaliście we wcześniejszym żądaniu (dodając rozszerzenie pliku, np. png) zamiast 404 otrzymacie obrazek o który nam chodzi (a w następnym żądaniu będzie 404 bo plik zostanie z bufora usunięty).

### Konkluzje

Każdy popełnia błędy to normalne (zwłaszcza w naszej branży), jednak chwalenie się jak to nasze rozwiązanie ułatwia nam życie a jednocześnie zatajanie ważnych błędów świadczących, że to rozwiązanie po prostu nie działa, jest co najmniej bezczelne. Nigdzie w dokumentacji ani w książkach o Seamie nie znajdziemy opisu tego problemu nikt nawet nie wspomni, że on występuje. A jest to tak oczywista funkcjonalność, że aż szokuje fakt, że nikt tego nie zauważył (a pewnie zauważyli, tylko woleli przemilczeć). Nieładnie panowie, nieładnie! A przecież jak jest upload to musi być i download!

Proponuję wam danie sobie spokój z Seam'ową obsługą dynamicznych zasobów. Napisanie odpowiedniego servletu jest bardzo łatwe i do tego bardzo łatwo zintegrować go z Seam'em tak aby mieć dostęp do jego komponentów (wkrótce może opiszę jak to zrobić). Nie rozumiem, czemu autorzy Seama tak usilnie chcą nam wciskać niedziałające rozwiązania, zamiast pokazać jak w oparciu o inne funkcjonalności tego frameworka rozwiązywać typowe problemy (nie na zasadzie Seam za nas wszystko zrobi). Ja w swoich programach całkowicie zrezygnowałem z `<s:graphicImage />` gdyż powodował on same problemy, a rozważam całkowite wyrzucenie servletu `SeamResourceServlet`.

Niestety takich badziewiastych rozwiązań, którymi twórcy tego frameworka się chwalą jakby nie wiadomo co stworzyli jest wiele. Dla przykładu testy integracyjne to wielu miejscach taki dramat, że tylko siąść i płakać. Spróbujcie kiedyś dojść na jakiej podstawie Seam odróżnia żądania postback'owe w testach integracyjnych, na przykład wtedy jak będziecie się zastanawiać dlaczego uruchamia wam się akcja w której zdefiniowaliście `on-postback="false"` (ten problem też kiedyś opiszę). Panowie powinni szczerze powiedzieć, że w wielu miejscach po prostu ich framework jest niedopracowany. Przecież nie ma w tym nic złego! A zaoszczędzi nam to czasu z walczeniem z rzeczami, które po prostu nie działają!

Nie chciałbym, aby ktokolwiek kto przeczytał ten wpis odniósł wrażenie, że nie lubię Seama. Wręcz przeciwnie, uważam ten framework za bardzo dobry. Denerwuje mnie jednak, jak ktoś wciska mi jako super rozwiązanie coś co po prostu nie działa z założenia. Przy okazji mam nadzieję, że zaoszczędzę komuś czasu, który ja poświęciłem na analizę problemu i działania tego frameworka.

Na koniec tylko dodam, że powyższy opis dotyczy frameworka Seam w wersji 2.2.0.GA.