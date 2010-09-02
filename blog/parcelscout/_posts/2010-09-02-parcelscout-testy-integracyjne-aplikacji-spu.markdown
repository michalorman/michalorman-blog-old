---
layout: post
title: ParcelScout - testy integracyjne dla aplikacji SPU
description: Konfiguracja i implementacja testów integracyjnych w maven dla aplikacji SPU.
keywords: maven testy integracyjne test integration-test jetty failsafe surefire h2
---
Aplikacja SPU, jak dotąd, nie dorobiła się zestawu testów potwierdzających, że wciąż działa jak należy. Za każdym razem jak zmieniałem coś w aplikacji
musiałem ręcznie, z konsoli sprawdzać czy wciąż wszystko działa prawidłowo, nie mówiąc już o ręcznym deploy'mencie. Oczywiście mogłem to sobie sprytnie
oskryptować, ale dalej wymagałoby to trochę ręcznej roboty. W każdym razie postanowiłem nadrobić brak sensownych testów integracyjnych (akceptując
jednocześnie brak testów jednostkowych ;).

To co postanowiłem sobie osiągnąć to tak skonfigurować aplikację, aby jedną komendą w mavenie aplikacja się budowała, instalowała na serwerze, serwer
był uruchamiany, odpalane były wszystkie testy integracyjne po czym następowało sprzątanie i ew. generowanie wyników testów. Dodatkowo założyłem sobie,
że testy mają uruchamiać się na innej bazie niż deweloperska. Dla dewelopmentu używam bazy PostgreSQL, jednakże dla testów integracyjnych chciałbym
użyć superszybkiej bazy [H2](http://www.h2database.com/html/main.html).

## Uruchamianie aplikacji z maven'a w Jetty

Budowanie aplikacji a także instalowanie i uruchamianie na serwerze okazało się dla mavena (prawie) banalną sprawą. Wystarczy w ``pom.xml`` uwzględnić
poniższą konfigurację:

{% highlight xml %}
<plugin>
    <groupId>org.mortbay.jetty</groupId>
    <artifactId>maven-jetty-plugin</artifactId>
    <version>6.1.25</version>
</plugin>
{% endhighlight %}

Od tej chwili aplikację możemy uruchamiać za pomocą komendy:

    mvn jetty:run

Kończymy natomiast skrótem ``Ctrl+C``. Jeżeli jednak uruchomienie nie powiedzie się i dostaniemy błąd w stylu:

    The plugin 'org.codehaus.mojo:jetty-maven-plugin' does not exist or no valid version could be found

Musimy do maven'owego pliku konfiguracyjnego ``settings.xml`` dodać:

{% highlight xml %}
<settings>
  <pluginGroups>
    <pluginGroup>org.mortbay.jetty</pluginGroup>
  </pluginGroups>
</settings>
{% endhighlight %}

## Testy integracyjne

Jest kilka sposobów na pisanie testów integracyjnych. Wiele osób preferuje posiadanie testów integracyjnych jako osobnego modułu. W sumie nie jest
to zły pomysł, jednak ja w tej aplikacji postanowiłem testy integracyjne umieścić w tym samym module co aplikacja.

Do uruchamiania testów integracyjnych z poziomu maven'a służy wtyczka ``maven-failsafe-plugin``. Aby skonfigurować tę wtyczkę w ``pom.xml`` należy
dopisać:

{% highlight xml %}
<plugin>
    <artifactId>maven-failsafe-plugin</artifactId>
    <version>2.6</version>
    <executions>
        <execution>
            <goals>
                <goal>integration-test</goal>
                <goal>verify</goal>
            </goals>
        </execution>
    </executions>
</plugin>
{% endhighlight %}

Testy integracyjne wywoływane zatem będą albo komendą ``mvn integration-test``, albo ``mvn verify``.

Domyślnie źródła testów w mavenie znajdują się w katalogu ``src/test/java``. Maven nie definiuje osobnego katalogu dla testów jednostkowych czy
integracyjnych, wszystkie wrzucane są do jednego wora, co nie jest zbytnio eleganckie. Aby odróżnić testy jednostkowe od integracyjnych wtyczka
``failsafe`` używa konwencji nazewniczej mówiącej, iż klasa testu integracyjnego powinna posiadać prefiks ``IT``. Należy także uważać, aby nazwa
klasy testowej nie kończyła się na ``Test`` ponieważ taka klasa zostanie uruchomiona przez wtyczkę ``surefire`` odpowiedzialną za testy
jednostkowe.

Zatem mając na uwadze konwencje nazewnicze możemy stworzyć dwie klasy testowe sprawdzające poprawność działania aplikacji. Jedna dla formatu
XML:

{% highlight java %}
public class ITXmlResponse {
    //...
}
{% endhighlight %}

Jedna dla JSON:

{% highlight java %}
public class ITJsonResponse {
    //...
}
{% endhighlight %}

Scenariusz testu jest prosty. Wysyłamy odpowiednie żądanie HTTP GET do aplikacji uruchomionej na serwerze Jetty i sprawdzamy odpowiedź. Aby wysłać
odpowiednio spreparowane żądanie wykorzystam bibliotekę [``HttpClient``](http://hc.apache.org/httpclient-3.x/). Zaczynamy od dodania zależności
do pliku ``pom.xml``:

{% highlight xml %}
<dependency>
    <groupId>commons-httpclient</groupId>
    <artifactId>commons-httpclient</artifactId>
    <version>3.1</version>
    <scope>test</scope>
</dependency>
{% endhighlight %}

Ponieważ biblioteka używana będzie w testach skonfigurowałem zakres ``test``. Żądania muszą być wysyłane pod pewien adres URL a adres ten
zależy od nazwy aplikacji (a dokładniej nazwy wynikowej war-a, który zostanie zbudowany). Mało roztropne zatem byłoby hardkodowanie tej
wartości. Lepszym rozwiązaniem jest konfigurowanie tej wartości w pliku ``pom.xml`` tam gdzie zdefiniowana jest też nazwa archiwum war.
Do tego celu możemy wykorzystać zmienne systemowe:

{% highlight xml %}
<properties>
    ...
    <pl.michalorman.spu.integration.host>localhost</pl.michalorman.spu.integration.host>
    <pl.michalorman.spu.integration.port>8080</pl.michalorman.spu.integration.port>
    <pl.michalorman.spu.integration.url>
        http://${pl.michalorman.spu.integration.host}:${pl.michalorman.spu.integration.port}/${project.build.finalName}/
    </pl.michalorman.spu.integration.url>
</properties>
...
<plugin>
    <artifactId>maven-failsafe-plugin</artifactId>
    ...
    <configuration>
        <systemPropertyVariables>
            <pl.michalorman.spu.integration.url>
                ${pl.michalorman.spu.integration.url}
            </pl.michalorman.spu.integration.url>
        </systemPropertyVariables>
    </configuration>
    ...
</plugin>
{% endhighlight %}

Warto zauważyć wykorzystanie zmiennej ``project.build.finalName`` do uzyskania ostatecznej nazwy archiwum. Teraz możemy
przejść do napisania bazowej klasy dla testów udostępniającej metody wysyłania żądań HTTP:

{% highlight java %}
public abstract class BaseITTest {
    private static String targetUrl;

    @BeforeClass
    public static void setUp() {
        targetUrl = System.getProperty("pl.michalorman.spu.integration.url");
    }

    protected String executeGetByExtension(String extension, String packageId) throws HttpException, IOException {
        return execute(format("%s/track.%s?packageId=%s", targetUrl, extension, packageId));
    }

    protected String executeGetByContentType(String contentType, String packageId) throws HttpException, IOException {
        return execute(format("%s/track?packageId=%s", targetUrl, packageId), contentType);
    }

    private String execute(String url) throws HttpException, IOException {
        return execute(url, null);
    }

    protected String execute(String url, String contentType) throws HttpException, IOException {
        HttpClient client = new HttpClient();
        GetMethod get = new GetMethod(url);
        if (contentType != null) {
            get.addRequestHeader("Content-Type", contentType);
        }
        client.executeMethod(get);
        return readResponse(get.getResponseBodyAsStream());
    }

    private String readResponse(InputStream input) throws IOException {
        BufferedReader reader = new BufferedReader(new InputStreamReader(input));
        StringBuilder builder = new StringBuilder();
        String line = null;
        while ((line = reader.readLine()) != null) {
            builder.append(line);
        }
        return builder.toString();
    }
}
{% endhighlight %}

Skonfigurowany adres URL jest pobierany w metodzie ``setUp()`` i ustawiany do zmiennej ``targetUrl``. W metodzie
``execute()`` zdecydowałem się odczytać odpowiedź jako strumień a nie jako obiekt ``String``, w przeciwnym razie
klient marudził o zbyt długich ciągach znaków albo nieznanej długości odpowiedzi, więc dla świętego spokoju zaimplementowałem
to w ten sposób.

Teraz możemy zaimplementować kilka testów. Najpierw dla formatu XML:

{% highlight java %}
public class ITXmlResponse extends BaseITTest {

    /*
     * Given HTTP GET request for *.xml should return successful response in XML format.
     */
    @Test
    public void shouldReturnXmlResponseForXmlExtension() throws HttpException, IOException {
        assertEquals(
                "<response status=\"101\"><package id=\"1\"><position latitude=\"53.43\" longitude=\"14.529\"/></package></response>",
                executeGetByExtension("xml", "1"));
       //...
    }

    // pozostałe testy...
}
{% endhighlight %}

Potem dla formatu JSON:

{% highlight java %}
public class ITJsonResponse extends BaseITTest {

    /*
     * Given HTTP GET request for *.json should return successful response in JSON format.
     */
    @Test
    public void shouldReturnJsonResponseForJsonExtension() throws HttpException, IOException {
        assertEquals(
                "{\"response\":{\"package\":{\"id\":1,\"position\":{\"latitude\":53.43,\"longitude\":14.529}},\"status\":101}}",
                executeGetByExtension("json", "1"));
        //...
    }

    // pozostałe testy...
}
{% endhighlight %}

Pewnie mógłbym się pokusić o bardziej wyrafinowane parsowanie odpowiedzi, ale z drugiej strony takie proste sprawdzenie
jest w zupełności wystarczające.

Testy zakładają, że w bazie istnieją już jakieś dane. Dane te, jak pisałem w [poprzednim](/parcelscout-orm-i-log4j-dla-paplikacji-spu/)
poście wrzucane są za pomocą pliku ``import.sql``. Problem w tym, że wrzucane są do bazy deweloperskiej, a ja chciałbym mieć je w bazie
testowej. No i w ogóle nie zdefiniowałem jeszcze tej bazy...

## Konfigurowanie bazy dla testów integracyjnych

W JPA konfiguracja bazy znajduje się w pliku ``META-INF/persistence.xml``. Stwórzmy zatem taki plik w katalogu ``src/test/resources``:

{% highlight xml %}
<persistence xmlns="http://java.sun.com/xml/ns/persistence" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://java.sun.com/xml/ns/persistence http://java.sun.com/xml/ns/persistence/persistence_2_0.xsd"
    version="2.0">
    <persistence-unit name="spu_service_test">
        <properties>
            <property name="hibernate.connection.driver_class" value="org.h2.Driver" />
            <property name="hibernate.connection.url" value="jdbc:h2:~/spu_service_test" />
            <property name="hibernate.connection.username" value="sa" />
            <property name="hibernate.connection.password" value="" />
            <property name="hibernate.dialect" value="org.hibernate.dialect.H2Dialect" />
            <property name="hibernate.show_sql" value="false" />
            <property name="hibernate.hbm2ddl.auto" value="create-drop" />
        </properties>
    </persistence-unit>
</persistence>
{% endhighlight %}

Jak wcześniej pisałem do testów chcę używać bazy H2. Aby móc skorzystać z tej bazy, muszę odpowiedni plik jar dodać do zależności
w pliku ``pom.xml``:

{% highlight xml %}
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <version>1.2.142</version>
    <scope>system</scope>
    <systemPath>${basedir}/lib/h2-1.2.142.jar</systemPath>
</dependency>
{% endhighlight %}

Tutaj sprawy się lekko komplikują. Dlaczego jako zakres ustawiłem ``system`` a nie ``test``? Ano z bibliotekami do połączenia z bazą,
czy to z samymi bazami jak H2 czy HSQLDB, czy z konektorami JDBC, jest tak, że są one zwykle dostarczane przez kontener a nie jako
zależność samej aplikacji. Jednakże w przypadku, gdy maven automatycznie instaluje dla nas aplikację na serwerze nie mamy zbytnio
możliwości dorzucenia do niego bibliotek. Więc mamy konflikt. Z jednej strony nie chcemy jar-a instalować razem z aplikacją, z drugiej
strony musimy, bo nie mamy innej możliwości dorzucenia go do kontenera, którym zarządza maven. Gdybym ustawił zakres ``test`` to
jar byłby widoczny w czasie testów jednostkowych, ale nie zostałby zainstalowany razem z war-em aplikacji. Dlaczego zatem nie ``provided``?
Ano dlatego, że Jetty nie dostarcza nam jar-a do bazy H2 a ręcznie go zainstalować nie możemy.

Rozwiązaniem tego impasu jest właśnie zakres ``system``. Działa on podobnie do ``provided`` z tą różnicą, że dostarczycielem zależności
nie jest kontener a aplikacja. W elemencie ``systemPath`` deklaruje się ścieżkę do zależności i jest ona widoczna dla naszej aplikacji
z poziomu kontenera uruchamianego przez mavena, ale jednocześnie nie jest pakowana w archiwum war. Co ważne podobną konfigurację trzeba
wykonać dla konektora JDBC dla bazy PostgreSQL jeżeli chcemy uruchamiać kontener z poziomu mavena za pomocą ``mvn jetty:run`` (no i nie można zapomnieć o
ściągnięciu bibliotek i wrzuceniu ich do katalogu ``lib`` ;).

### Problemy z plikiem persistence.xml

Niestety na problemach z samą zależnością do bibliotek bazy się nie kończy. Z niewiadomych dla mnie przyczyn do testów nie jest brany
plik ``src/test/resources/META-INF/persistence.xml`` a ``src/main/resources/META-INF/persistence.xml``. Czyli mimo, iż skonfigurowaliśmy
bazę H2 do testów, to same testy będą korzystać z bazy deweloperskiej (która jest PostrgreSQL). Nie wiem czy jest to problem samego
mavena, czy wtyczki ``failsafe``.

Aby rozwiązać ten problem musimy sami przed uruchomieniem testów jednostkowych utworzyć kopię głównego pliku ``persistence.xml``,
nadpisać go wersją z testów, a na końcu przywrócić kopię. O przywróceniu kopii nie można zapomnieć, gdyż inaczej musielibyśmy
podczas budowania aplikacji za pomocą komendy ``mvn package`` pamiętać o wyłączeniu testów. No to wiemy co należy zrobić, a do takiego
zadania doskonale nadają się Ant-owe zadania, które można definiować w mavenie:

{% highlight xml %}
<plugin>
    <artifactId>maven-antrun-plugin</artifactId>
    <version>1.4</version>
    <executions>
        <execution>
            <id>copy-test-persistence</id>
            <phase>prepare-package</phase>
            <configuration>
                <tasks>
                    <copy file="${project.build.outputDirectory}/META-INF/persistence.xml"
                        tofile="${project.build.outputDirectory}/META-INF/persistence.xml.bk"
                        verbose="true" />
                    <copy file="${basedir}/src/test/resources/META-INF/persistence.xml"
                        tofile="${project.build.outputDirectory}/META-INF/persistence.xml"
                        overwrite="true" verbose="true" />
                </tasks>
            </configuration>
            <goals>
                <goal>run</goal>
            </goals>
        </execution>
        <execution>
            <id>restore-persistence</id>
            <phase>post-integration-test</phase>
            <configuration>
                <tasks>
                    <copy file="${project.build.outputDirectory}/META-INF/persistence.xml.bk"
                        tofile="${project.build.outputDirectory}/META-INF/persistence.xml"
                        overwrite="true" verbose="true" />
                </tasks>
            </configuration>
            <goals>
                <goal>run</goal>
            </goals>
        </execution>
    </executions>
</plugin>
{% endhighlight %}

Kopiujemy wersję testową w fazie ``prepare-package``, a przywracamy w fazie ``post-integration-test``. Dzięki temu w testach będzie
używana testowa wersja pliku a zbudowanym archiwum będziemy mieć oryginalną.

### Uruchamianie Jetty do testów

W tym momencie pozostała już tylko jedna rzecz, aby nasze testy działały. Musimy powiedzieć maven'owi, aby uruchamiał kontener Jetty
przed uruchomieniem testów i zamykał po. Robimy to w konfiguracji wtyczki ``maven-jetty-plugin``:

{% highlight xml %}
<plugin>
    <groupId>org.mortbay.jetty</groupId>
    <artifactId>maven-jetty-plugin</artifactId>
    <version>6.1.25</version>
    <configuration>
        <scanIntervalSeconds>5</scanIntervalSeconds>
        <stopKey>foo</stopKey>
        <stopPort>9999</stopPort>
    </configuration>
    <executions>
        <execution>
            <id>start-jetty</id>
            <phase>pre-integration-test</phase>
            <goals>
                <goal>run</goal>
            </goals>
            <configuration>
                <scanIntervalSeconds>0</scanIntervalSeconds>
                <daemon>true</daemon>
            </configuration>
        </execution>
        <execution>
            <id>stop-jetty</id>
            <phase>post-integration-test</phase>
            <goals>
                <goal>stop</goal>
            </goals>
        </execution>
    </executions>
</plugin>
{% endhighlight %}

Aby móc skorzystać z ``mvn jetty:stop`` musimy skonfigurować ``stopKey`` oraz ``stopPort``. W fazie ``pre-integration-test`` maven
uruchomi ``jetty:run``, a w fazie ``post-integration-test`` komendę ``jetty:stop``. Co ważne musimy uruchomić kontener z parametrem
``daemon`` ustawionym na ``true`` aby maven mógł dalej realizować swoje zadania.

## Odpalanie testów integracyjnych

To tyle jeżeli chodzi o konfigurację, teraz możemy odpalić testy integracyjne za pomocą jednej maven'owej komendy:

{% highlight bash %}
$ mvn verify
...
[INFO] Executing tasks
     [copy] Copying 1 file to /home/snc/work/parcelscout/work/spu-service/target/classes/META-INF
     [copy] Copying /home/snc/work/parcelscout/work/spu-service/target/classes/META-INF/persistence.xml to /home/snc/work/parcelscout/work/spu-service/target/classes/META-INF/persistence.xml.bk
     [copy] Copying 1 file to /home/snc/work/parcelscout/work/spu-service/target/classes/META-INF
     [copy] Copying /home/snc/work/parcelscout/work/spu-service/src/test/resources/META-INF/persistence.xml to /home/snc/work/parcelscout/work/spu-service/target/classes/META-INF/persistence.xml
...
[INFO] Packaging webapp
[INFO] Assembling webapp[spu-service] in [/home/snc/work/parcelscout/work/spu-service/target/spu-service]
...
[INFO] Building war: /home/snc/work/parcelscout/work/spu-service/target/spu-service.war
[INFO] Preparing jetty:run
...
[INFO] Starting jetty 6.1.25 ...
...
-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running pl.michalorman.spu.integration.ITXmlResponse
20:44:27.678 INFO  [231159742@qtp-1342263456-0] - Received request for /track.xml with params: packageId='1'
20:44:27.905 INFO  [2117615354@qtp-1342263456-2] - Received request for /track.xml with params: packageId='2'
20:44:27.920 INFO  [2117615354@qtp-1342263456-2] - Received request for /track.xml with params: packageId='3'
20:44:27.927 INFO  [2117615354@qtp-1342263456-2] - Received request for /track.xml with params: packageId='4'
20:44:27.936 INFO  [2117615354@qtp-1342263456-2] - Received request for /track.xml with params: packageId='5'
20:44:27.977 INFO  [2117615354@qtp-1342263456-2] - Received request for /track.xml with params: packageId='6'
20:44:27.979 WARN  [2117615354@qtp-1342263456-2] - Requested package with id='6' not found
20:44:28.011 INFO  [325087472@qtp-1342263456-3] - Received request for /track with content-type=application/xml and params: packageId='1'
20:44:28.019 INFO  [325087472@qtp-1342263456-3] - Received request for /track with content-type=application/xml and params: packageId='2'
20:44:28.028 INFO  [325087472@qtp-1342263456-3] - Received request for /track with content-type=application/xml and params: packageId='3'
20:44:28.035 INFO  [2117615354@qtp-1342263456-2] - Received request for /track with content-type=application/xml and params: packageId='4'
20:44:28.043 INFO  [2117615354@qtp-1342263456-2] - Received request for /track with content-type=application/xml and params: packageId='5'
20:44:28.050 INFO  [2117615354@qtp-1342263456-2] - Received request for /track with content-type=application/xml and params: packageId='6'
20:44:28.051 WARN  [2117615354@qtp-1342263456-2] - Requested package with id='6' not found
Tests run: 4, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.191 sec
Running pl.michalorman.spu.integration.ITJsonResponse
20:44:28.119 INFO  [2117615354@qtp-1342263456-2] - Received request for /track.json with params: packageId='6'
20:44:28.121 WARN  [2117615354@qtp-1342263456-2] - Requested package with id='6' not found
20:44:28.192 INFO  [2117615354@qtp-1342263456-2] - Received request for /track with content-type=application/json and params: packageId='1'
20:44:28.200 INFO  [2117615354@qtp-1342263456-2] - Received request for /track with content-type=application/json and params: packageId='2'
20:44:28.208 INFO  [2117615354@qtp-1342263456-2] - Received request for /track with content-type=application/json and params: packageId='3'
20:44:28.215 INFO  [2117615354@qtp-1342263456-2] - Received request for /track with content-type=application/json and params: packageId='4'
20:44:28.221 INFO  [2117615354@qtp-1342263456-2] - Received request for /track with content-type=application/json and params: packageId='5'
20:44:28.239 INFO  [2117615354@qtp-1342263456-2] - Received request for /track with content-type=application/json and params: packageId='6'
20:44:28.241 WARN  [2117615354@qtp-1342263456-2] - Requested package with id='6' not found
20:44:28.260 INFO  [2117615354@qtp-1342263456-2] - Received request for /track.json with params: packageId='1'
20:44:28.271 INFO  [2117615354@qtp-1342263456-2] - Received request for /track.json with params: packageId='2'
20:44:28.277 INFO  [2117615354@qtp-1342263456-2] - Received request for /track.json with params: packageId='3'
20:44:28.288 INFO  [2117615354@qtp-1342263456-2] - Received request for /track.json with params: packageId='4'
20:44:28.293 INFO  [2117615354@qtp-1342263456-2] - Received request for /track.json with params: packageId='5'
Tests run: 4, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.208 sec

Results :

Tests run: 8, Failures: 0, Errors: 0, Skipped: 0
...
[INFO] Executing tasks
     [copy] Copying 1 file to /home/snc/work/parcelscout/work/spu-service/target/classes/META-INF
     [copy] Copying /home/snc/work/parcelscout/work/spu-service/target/classes/META-INF/persistence.xml.bk to /home/snc/work/parcelscout/work/spu-service/target/classes/META-INF/persistence.xml
...
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESSFUL
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 17 seconds
...
20:44:29.209 INFO  [StopJettyPluginMonitor] - closing
...
2010-09-02 20:44:29.288:INFO::Shutdown hook executing
2010-09-02 20:44:29.590:INFO::Shutdown hook complete
{% endhighlight %}

## Podsumowanie

Teraz aplikacja SPU nie boi się żadnego refaktoringu. Po każdej zmianie za pomocą jednej konsolowej komendy odpalam
pełne testy integracyjne uruchamiane na kontenerze z własną bazą testową. Co prawda trochę to wymagało konfiguracji,
ale efekt końcowy jest zadowalający. Jako swoisty efekt uboczny otrzymałem możliwość uruchamiania aplikacji również
z poziomu konsoli wraz z włączonym hot-deploy'mentem dzięki czemu nie muszę korzystać z IDE. Teraz spokojnie mogę
brać się za dalsze modyfikacje aplikacji.

Gdyby ktoś podczas uruchamiania testów integracyjnych natknął się na taki błąd:

{% highlight bash %}
org.h2.jdbc.JdbcSQLException: Database is already closed (to disable automatic closing at VM shutdown, add ";DB_CLOSE_ON_EXIT=FALSE" to the db URL) [90121-142]
        at org.h2.message.DbException.getJdbcSQLException(DbException.java:327) ~[h2-1.2.142.jar:1.2.142]
        at org.h2.message.DbException.get(DbException.java:167) ~[h2-1.2.142.jar:1.2.142]
        at org.h2.message.DbException.get(DbException.java:144) ~[h2-1.2.142.jar:1.2.142]
        at org.h2.message.DbException.get(DbException.java:133) ~[h2-1.2.142.jar:1.2.142]
        at org.h2.jdbc.JdbcConnection.checkClosed(JdbcConnection.java:1348) ~[h2-1.2.142.jar:1.2.142]
        at org.h2.jdbc.JdbcConnection.checkClosed(JdbcConnection.java:1323) ~[h2-1.2.142.jar:1.2.142]
        at org.h2.jdbc.JdbcConnection.getAutoCommit(JdbcConnection.java:386) ~[h2-1.2.142.jar:1.2.142]
        at org.hibernate.connection.DriverManagerConnectionProvider.getConnection(DriverManagerConnectionProvider.java:127) ~[hibernate-core-3.5.5-Final.jar:3.5.5-Final]
        at org.hibernate.tool.hbm2ddl.SuppliedConnectionProviderConnectionHelper.prepare(SuppliedConnectionProviderConnectionHelper.java:51) ~[hibernate-core-3.5.5-Final.jar:3.5.5-Final]
        at org.hibernate.tool.hbm2ddl.SchemaExport.execute(SchemaExport.java:252) [hibernate-core-3.5.5-Final.jar:3.5.5-Final]
...
{% endhighlight %}

Trzeba postąpić zgodnie z tym co nam sugerują, czyli dodać ``;DB_CLOSE_ON_EXIT=FALSE`` do URL-a:

{% highlight xml %}
<property name="hibernate.connection.url" value="jdbc:h2:~/spu_service_test;DB_CLOSE_ON_EXIT=FALSE" />
{% endhighlight %}

Problem ten nie występuje zawsze. Wygląda na to, że jest tu jakiś wyścig (może Jetty vs. maven). W każdym razie powyższa
konfiguracja załatwia sprawę raz na zawsze.

Za namowami w komentarzach do mojego poprzedniego postu zmieniłem system logowania z Log4J na SLF4J + Logback. Dodatkowo poprawiłem błąd polegający
na niewłaściwym umiejscowieniu adnotacji ``@Transactional``. W poprzedniej wersji znajdowała się ona na metodach obiektu
DAO. Problem w tym, że z tych obiektów korzystają serw... ekhem... usługi (klasy usługowe? ;). Pic polega na tym, że w jednej
metodzie takiej klasy może występować kilka odwołań do warstwy DAO i każde takie odwołanie będzie realizowane w ramach swojej,
izolowanej transakcji (zgodnie z założeniami [ACID](http://pl.wikipedia.org/wiki/ACID)). Z punktu widzenia logiki biznesowej to
jest poważny błąd, ponieważ cała operacja biznesowa (usługowa) powinna być realizowana jako jedna, autonomiczna transakcja. Tutaj sam do głowy przychodzi
przykład przelewu bankowego, gdzie w jednej transakcji pobieramy kasę z jednego konta a w drugiej transakcji wpłacamy na inne
konto. Z punktu widzenia logiki biznesowej transakcyjny jest przelew a nie wpłata czy wypłata. Zatem obecne rozwiązanie wymaga,
aby obiekt DAO był uruchamiany w ramach już istniejącej transakcji:

{% highlight java %}
@Repository("packageDao")
@Transactional(propagation = Propagation.MANDATORY)
public class JpaPackageDao implements PackageDao {
    //...
}
{% endhighlight %}

Natomiast transakcja jest rozpoczynana w klasie usługowej:

{% highlight java %}
@Service
public class PackageTrackService {
    @Transactional
    public TrackResponse getTrackInfo(Integer packageId) {
        //...
    }
}
{% endhighlight %}

Być może poszukam jakiegoś ciekawszego rozwiązania, ale powyższe jest wystarczające na potrzeby aplikacji (poprzednie swoją
drogą też, ale nie chciałem szerzyć złych praktyk ;).

Kod tradycyjnie do obejrzenia na moim profilu GitHub: [http://github.com/michalorman/parcelscout/tree/master/work/spu-service](http://github.com/michalorman/parcelscout/tree/master/work/spu-service).