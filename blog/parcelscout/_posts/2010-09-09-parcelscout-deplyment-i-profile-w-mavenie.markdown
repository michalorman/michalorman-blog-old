---
layout: post
title: ParcelScout - Deployment i profile w mavenie
description: Wpis na temat konfiguracji deploy'mentu i profili w mavenie.
keywords: Maven deploy build profile
---
Aplikacja SPU jest już praktycznie gotowa, ostatnią rzeczą jaka pozostała to skonfigurowanie deploy'mentu (nie znam dobrego, polskiego odpowiednika
tego słowa). Aplikację instalować będę na jednym z bardziej popularnych kontenerów [Tomcat'cie](http://tomcat.apache.org/). Kontener ten jest dość szybki i
łatwy w konfiguracji stąd wybór padł właśnie na niego.

## Konfiguracja deploy'mentu w mavenie

Do deploymentu na serwer Tomcat wykorzystam wtyczkę [``tomcat-maven-plugin``](http://mojo.codehaus.org/tomcat-maven-plugin/). Wtyczka ta wykorzystuje narzędzie
**Tomcat Web Application Manager**, które dostarczane jest wraz z samym kontenerem. Aby móc skorzystać z tego narzędzia musimy skonfigurować użytkownika, wraz
z odpowiednimi uprawnieniami, który będzie mógł instalować aplikację na kontenerze. Użytkownicy konfigurowanie są w pliku konfiguracyjnym znajdującym
się w katalogu ``${TOMCAT_HOME}/conf/tomcat-users.xml``:

{% highlight xml %}
<tomcat-users>
  <user username="tomcat" password="tomcat" roles="manager"/>
</tomcat-users>
{% endhighlight %}

Użytkownik musi posiadać rolę ``manager`` aby mógł korzystać z narzędzia.

Kolejną rzeczą jest stworzenie profilu serwera w maven'owym pliku konfiguracyjnym ``settings.xml``:

{% highlight xml %}
<settings>
  ...
  <servers>
    <server>
      <id>tomcat-spu-service-prod</id>
      <username>tomcat</username>
      <password>tomcat</password>
    </server>
  </server>
  ...
</settings>
{% endhighlight %}

W ten sposób utworzyliśmy profil o nazwie ``tomcat-spu-service-prod`` podając odpowiednią nazwę użytkownika i hasło dostępu do narzędzia managera. Polecam
przeglądnięcie dokumentacji maven'a, gdyż maven pozwala na zdecydowanie lepszą konfigurację (np. w oparciu o klucze SSH).

Mając już profil możemy przejść do konfiguracji samej wtyczki:

{% highlight xml %}
<project>
  ...
  <build>
    ...
    <plugin>
      <groupId>org.codehaus.mojo</groupId>
      <artifactId>tomcat-maven-plugin</artifactId>
      <version>1.0</version>
      <configuration>
        <server>tomcat-spu-service-prod</server>
        <url>http://localhost:8100/manager</url>
        <path>/</path>
      </configuration>
    </plugin>
    ...
  </build>
  ...
</project>
{% endhighlight %}

Konfigurujemy użycie naszego profilu w elemencie ``server``. Element ``url`` określa adres pod którym będzie dostępna aplikacja manager'a (domyślnie jest to
``http://localhost:8080/manager`` i nie ma potrzeby konfiguracji tego parametru, ponieważ jednak ja zmieniłem port, na którym kontener ma nasłuchiwać, to musiałem
skonfigurować adres). Ostatni element ``path`` służy do skonfigurowania ścieżki kontekstu (ang. *context path*), czyli adresu pod jakim będzie dostępna aplikacja.
Domyślnie wartość ta jest taka sama jak ``artifactId`` dla projektu, jednak ja zdecydowałem, że aplikacja ma być dostępna jako tzw. *context root*.

To tyle, jeżeli chodzi o konfigurację. Teraz możemy zainstalować na (uruchomionym) kontenerze naszą aplikację za pomocą komendy:

    mvn tomcat:redeploy

Istnieje jeszcze komenda ``mvn tomcat:deploy`` jednak ta komenda nie powiedzie się w przypadku gdy pod daną ścieżką kontekstu jest już aplikacja, a ponieważ na ścieżce
*context root* zawsze jest jakaś (chyba w każdym kontenerze), dlatego nasz celem powinno być ``tomcat:redeploy``.

Wtyczka pozwala nam skorzystać z innych komend tj. ``tomcat:info`` czy ``tomcat:list``. Polecam przeglądnięcie dokumentacji w celu sprawdzenia dostępnych opcji.

## Profile w mavenie

Dla aplikacji SPU jakiś czas temu powstały [testy integracyjne](/blog/2010/09/parcelscout-testy-integracyjne-aplikacji-spu/). W testach tych musiałem zaimplementować
ręczne kopiowanie pliku ``persistence.xml`` z ``src/test/resources``. Pisałem wtedy, że podczas normalnego budowania (``mvn package``) wersja testowa nie będzie kopiowana
(a właściwie zostanie przywrócona jej oryginalna wersja).
Niestety pośpieszyłem się jednak z tym stwierdzeniem. Otóż przywracanie oryginalnego pliku dzieje się w fazie ``post-integration-test``, jednak faza ta nie jest
wywoływana przy budowaniu aplikacji, stąd wykorzystując mechanizm deploy'mentu będziemy mieć zawsze testową wersję deskryptora ``persistence.xml``. Rozwiązaniem (i to
całkiem dobrym) tego problemu okazały się [profile](http://maven.apache.org/guides/introduction/introduction-to-profiles.html) (ang. *build profiles*).

Profile pozwalają nam wykonywać pewne akcje inaczej w zależności od wybranego profilu. Intuicyjnie każdy programista potrafi wymienić przynajmniej 3 takie profile tj.
produkcyjny, deweloperski i testowy. Można zatem utworzyć 3 pliki ``persistence.xml``, po jednym dla każdego profilu (tj. ``persistence-prod.xml``, ``persistence-dev.xml``,
oraz ``persistence-test.xml``), i wybierać ten, który w danym profilu powinien zostać zastosowany (podobne rozwiązanie zostało zastosowane we frameworku [Seam](http://seamframework.org/)).
Taka konfiguracja mogłaby wyglądać następująco:

{% highlight xml %}
<profiles>
    <profile> <!-- develpment -->
        <id>dev</id>
        <activation>
            <activeByDefault>true</activeByDefault>
        </activation>
        <build>
            <plugins>
                <plugin>
                    <artifactId>maven-antrun-plugin</artifactId>
                    <version>1.4</version>
                    <executions>
                        <execution>
                            <id>prepare-persistence</id>
                            <phase>prepare-package</phase>
                            <configuration>
                                <tasks>
                                    <copy file="${project.build.outputDirectory}/META-INF/persistence-dev.xml"
                                          tofile="${project.build.outputDirectory}/META-INF/persistence.xml"
                                          verbose="true" overwrite="true"/>
                                    <delete file="${project.build.outputDirectory}/META-INF/persistence-dev.xml"
                                            verbose="true"/>
                                    <delete file="${project.build.outputDirectory}/META-INF/persistence-prod.xml"
                                            verbose="true"/>
                                </tasks>
                            </configuration>
                            <goals>
                                <goal>run</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin>
            </plugins>
        </build>
    </profile>
    <profile>
        <id>prod</id><!-- production -->
        <build>
            <plugins>
                <plugin>
                    <artifactId>maven-antrun-plugin</artifactId>
                    <version>1.4</version>
                    <executions>
                        <execution>
                            <id>prepare-persistence</id>
                            <phase>prepare-package</phase>
                            <configuration>
                                <tasks>
                                    <copy file="${project.build.outputDirectory}/META-INF/persistence-prod.xml"
                                          tofile="${project.build.outputDirectory}/META-INF/persistence.xml"
                                          verbose="true" overwrite="true"/>
                                    <delete file="${project.build.outputDirectory}/META-INF/persistence-dev.xml"
                                            verbose="true"/>
                                    <delete file="${project.build.outputDirectory}/META-INF/persistence-prod.xml"
                                            verbose="true"/>
                                </tasks>
                            </configuration>
                            <goals>
                                <goal>run</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin>
                <plugin>
                    <groupId>org.codehaus.mojo</groupId>
                    <artifactId>tomcat-maven-plugin</artifactId>
                    <version>1.0</version>
                    <configuration>
                        <server>tomcat-spu-service-prod</server>
                        <url>http://localhost:8100/manager</url>
                        <path>/</path>
                    </configuration>
                </plugin>
            </plugins>
        </build>
    </profile>
    <profile>
        <id>test</id><!-- test -->
        <build>
            <plugins>
                <plugin>
                    <artifactId>maven-antrun-plugin</artifactId>
                    <version>1.4</version>
                    <executions>
                        <execution>
                            <id>prepare-persistence</id>
                            <phase>prepare-package</phase>
                            <configuration>
                                <tasks>
                                    <copy file="${basedir}/src/test/resources/META-INF/persistence-test.xml"
                                          tofile="${project.build.outputDirectory}/META-INF/persistence.xml"
                                          verbose="true" overwrite="true"/>
                                    <delete file="${project.build.outputDirectory}/META-INF/persistence-dev.xml"
                                            verbose="true"/>
                                    <delete file="${project.build.outputDirectory}/META-INF/persistence-prod.xml"
                                            verbose="true"/>
                                </tasks>
                            </configuration>
                            <goals>
                                <goal>run</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin>
            </plugins>
        </build>
    </profile>
</profiles>
{% endhighlight %}

W zależności od profilu (``dev``, ``prod`` czy ``test``) odpowiedni plik jest zapisywany jako ``persistence.xml`` a niepotrzebne są usuwane. Dodatkowo
w profilu ``prod`` skonfigurowany został deployment na Tomcat'a, ponieważ tylko w tym profilu jest to potrzebne, w pozostałych możemy skorzystać z
komendy ``mvn jetty:run``. Warto również zauważyć, iż profil ``dev`` został skonfigurowany jako domyślny (element ``activeByDefault``) dzięki czemu ten
profil zostanie uaktywniony w przypadku braku parametru jawnie określającego profil.

Jak z tego skorzystać? Bardzo prosto, chcemy zbudować paczkę deweloperską:

    mvn clean package

Paczkę produkcyjną:

    mvn clean package -P prod

Chcemy zweryfikować konfigurację? Możemy zarówno deweloperską, testową jak i produkcyjną:

    mvn verify -P prod

Chcemy deploymentu na produkcję? Proszę bardzo:

    mvn tomcat:redeploy -P prod

Teraz możemy zdefiniować osobne konfiguracje w zależności od środowiska uruchomieniowego i ona zostanie wykorzystana w danym profilu.

## Podsumowanie

Dzięki narzędziu maven aplikacja SPU została wzbogacona o możliwość bezpośredniego instalowania aplikacji na kontenerze Tomcat. Dodatkowo wykorzystując
mechanizm profili aplikacja posiada osobną konfigurację dla środowiska deweloperskiego, produkcyjnego i testowego. W tym momencie można zostawić na chwilę
tę aplikację i zająć się kolejnymi elementami [infrastruktury](/blog/2010/08/parcelscout-założenia-i-architektura/) (o tym będzie traktował kolejny wpis).

Kod aplikacji jak zawsze dostępny na moim profilu GitHub: [http://github.com/michalorman/parcelscout/tree/master/work/spu-service/](http://github.com/michalorman/parcelscout/tree/master/work/spu-service/),

Dodatkowo jeżeli ktoś chciałby powyższą konfigurację zastosować w swoim projekcie to udostępniłem ją w formie archetypu mavena:
[http://github.com/michalorman/spring-web-service-archetype](http://github.com/michalorman/spring-web-service-archetype). Aby móc z niej skorzystać
trzeba ją ściągnąć (opcja *Download source* u góry strony) przejść do katalogu archetypu i go zainstalować komendą ``mvn install``. Jak mamy już zainstalowany
możemy stworzyć projekt w oparciu o ten archetyp ``mvn archetype:generate -DarchetypeCatalog=local`` i wybieramy opcję ``spring-web-service-archetype``.
