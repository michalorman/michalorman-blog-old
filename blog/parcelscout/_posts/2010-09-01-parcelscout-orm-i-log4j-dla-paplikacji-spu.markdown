---
layout: post
title: ParcelScout ORM i Log4J dla aplikacji SPU
description: Konfiguracja ORM (JPA i Hibernate EntityManager) w Spring.
keywords: Spring MVC ORM JPA Log4J Hibernate EntityManager
---
[Ostatnim](/blog/2010/08/parcelscout-refaktoring-serwisu-spu/) razem refaktorowałem aplikację dla SPU poprawiając format wyniku oraz
dodając odpowiedzi w formacie JSON (wybór formatu możliwy jest na podstawie rozszerzenia lub parametru Content-Type nagłówka HTTP).
Tym razem postanowiłem rozwinąć aplikację o warstwę persystencji oraz logowanie.

Jako standard ORM wybrałem JPA a jako implementację [Hibernate EntityManager](http://www.hibernate.org/). Do logowania natomiast użyję frameworka [Log4J](http://logging.apache.org/log4j/1.2/).
Zatem nie ma co dłużej zwlekać, trzeba brać się do roboty.

## Dodanie wsparcia mapowania obiektowo-relacyjnego (ORM)

Jest kilka sposobów skonfigurowania JPA dla Springa. Ten, który przedstawię jest o tyle dobry, że opiera się o standardowe adnotacje
JPA i nie wykorzystuje w naszych klasach modelu czy DAO żadnych zależności do Springa (przez co, przynajmniej teoretycznie, łatwe jest
przeniesienie aplikacji do np. kontenera EJB).

Pierwszym elementem jest oczywiście dodanie zależności do pliku ``pom.xml``:

{% highlight xml %}
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-orm</artifactId>
    <version>${org.springframework.version}</version>
</dependency>

<dependency>
    <groupId>org.hibernate</groupId>
    <artifactId>hibernate-entitymanager</artifactId>
    <version>3.5.5-Final</version>
</dependency>
{% endhighlight %}

Musimy dodać zależności zarówno do samego ``hibernate-entitymanager`` jak i ``spring-orm``, biblioteki która to oferuje nam wszelkie Springowe wsparcie
dla ORM.

Mając już zależności możemy nałożyć adnotacje JPA na nasz model. Najpierw klasa ``Package``:

{% highlight java %}
@Entity
@Table(name = "packages")
public class Package {

    @XStreamAsAttribute
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Embedded
    private Position position;

    // gettery i settery
}
{% endhighlight %}

Potem klasa ``Position``:

{% highlight java %}
@Embeddable
public class Position {

    @XStreamAsAttribute
    @Column(nullable = false)
    private Double latitude;

    @XStreamAsAttribute
    @Column(nullable = false)
    private Double longitude;

   // gettery i settery...
}
{% endhighlight %}

Teraz potrzebujemy obiektu, który będzie nam wyciągał dane z bazy. Jak dobra praktyka nakazuje zrobimy warstwę [DAO](http://pl.wikipedia.org/wiki/Data_Access_Object),
która odseparuje nam konkretny mechanizm ORM od reszty aplikacji (tak na wypadek jakby mi kiedyś przyszło do głowy zrezygnować z JPA i przerzucić się na czystego
Hibernate'a). A więc definiujemy interfejs:

{% highlight java %}
public interface PackageDao {

    public Package findById(Integer packageId);

}
{% endhighlight %}

I tworzymy jego implementację:

{% highlight java %}
@Repository("packageDao")
@Transactional
public class JpaPackageDao implements PackageDao {

    @PersistenceContext
    private EntityManager entityManager;

    @Override
    public Package findById(Integer packageId) {
        return entityManager.find(Package.class, packageId);
    }

}
{% endhighlight %}

W JPA faktycznymi odwołaniami do bazy zajmuje się obiekt ``EntityManager`` (który odseparowuje nam nasze obiekty, od faktycznych wywołań SQL-owych zależnych
od używanej bazy). W przypadku gdy aplikacja uruchamiana jest w jakimś kontenerze Java EE to kontener odpowiedzialny jest za tworzenie obiektu ``EntityManager'a``,
który następnie wstrzykiwany jest do komponentu za pomocą adnotacji ``@PersistenceContext``. Jednakże w przypadku aplikacji Java SE (takiej, jaką jest aplikacja
SPU) musimy zadbać o to sami. Na szczęście przy odrobinie konfiguracji (o której za chwilę) Spring zajmie się tym za nas i nie musimy martwić się o ręczne
tworzenie ``EntityManager'a`` czy otwieranie lub zamykanie transakcji. Co więcej wsparcie Springa rozumie takie adnotacje jak ``@PersitenceContext`` czy
``@PersitenceUnit`` przez co nasze DAO są bardziej JPA niż Spring-owe.

Skoro już przy transakcjach jesteśmy to warto zauważyć, iż nałożyłem na klasę adnotację ``@Transactional`` dzięki czemu każda metoda będzie wywoływana w ramach
otwartej transakcji i każde odwołanie do bazy (w tej metodzie) będzie realizowane w jej ramach. Znów jest to konieczne, ponieważ nasza aplikacja to Java SE a nie
EE (gdzie komponenty EJB są transakcyjne z definicji).

Ostatnia adnotacja ``@Repository`` służy dwóm celom. Po pierwsze jako, że jest to stereotyp Spring-a tworzy nam komponent ``packageDao``, który możemy wstrzykiwać
innym komponentom. Po drugie wszelkie wyjątki dotyczące dostępu do bazy będą opakowane w klasy Spring-owe, przez co w serwisach nie musimy się zastanawiać czy
mamy do czynienia z JPA czy Hibernatem (i czy łapać dla przykładu ``HibernateException`` czy ``PersistenceException``).

Ok, mamy warstwę DAO, teraz trzeba zmodyfikować nasz serwis:

{% highlight java %}
@Service
public class PackageTrackService {
    @Autowired
    private PackageDao packageDao;

    public TrackResponse getTrackInfo(Integer packageId) {
        Package parcel = packageDao.findById(packageId);
        if (parcel != null) {
            return TrackResponse.successResponse(parcel);
        }
        return TrackResponse.failureResponse();
    }
}
{% endhighlight %}

Wstrzyknięty obiekt DAO odpytujemy o odpowiednią paczkę i w zależności czy taka istnieje tworzymy odpowiednią odpowiedź, która zostanie przesłana do widoku
celem wyrenderowania (bądź to jako XML bądź JSON).

### Konfiguracja ORM w Spring

Aby skonfigurować ORM w frameworku Spring trzeba zrobić trzy rzeczy:

1. Zdefiniować komponent ``EntityManagerFactory``.
2. Zdefiniować komponent ``TransactionManager``.
3. Opcjonalnie powiedzieć Springowi, że transakcje definiowane są na poziomie adnotacji (a nie pliku XML).

Powyższa konfiguracja w pliku ``track-servlet.xml`` wygląda następująco:

{% highlight xml %}
<beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:p="http://www.springframework.org/schema/p" xmlns:context="http://www.springframework.org/schema/context"
    xmlns:oxm="http://www.springframework.org/schema/oxm" xmlns:tx="http://www.springframework.org/schema/tx"
    xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.0.xsd
                http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context-3.0.xsd
                http://www.springframework.org/schema/oxm http://www.springframework.org/schema/oxm/spring-oxm-3.0.xsd
                http://www.springframework.org/schema/tx http://www.springframework.org/schema/tx/spring-tx-3.0.xsd">

    ...

    <tx:annotation-driven />

    <bean id="entityManagerFactory" class="org.springframework.orm.jpa.LocalEntityManagerFactoryBean" />

    <bean id="transactionManager" class="org.springframework.orm.jpa.JpaTransactionManager">
        <property name="entityManagerFactory" ref="entityManagerFactory" />
    </bean>

    ...

</beans>
{% endhighlight %}

To tyle jeżeli chodzi o Spring, pozostała nam już tylko konfiguracja samego JPA, co należy uczynić w pliku ``persistence.xml``:

{% highlight xml %}
<persistence xmlns="http://java.sun.com/xml/ns/persistence" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://java.sun.com/xml/ns/persistence http://java.sun.com/xml/ns/persistence/persistence_2_0.xsd"
    version="2.0">

    <persistence-unit name="spu_service_devel">
        <properties>
            <property name="hibernate.connection.driver_class" value="org.postgresql.Driver" />
            <property name="hibernate.connection.url" value="jdbc:postgresql://localhost/spu_service_devel" />
            <property name="hibernate.connection.username" value="postgres" />
            <property name="hibernate.connection.password" value="secret" />
            <property name="hibernate.dialect" value="org.hibernate.dialect.PostgreSQLDialect" />
            <property name="hibernate.show_sql" value="true" />
            <property name="hibernate.hbm2ddl.auto" value="create-drop" />
        </properties>
    </persistence-unit>

</persistence>
{% endhighlight %}

Jak widać na powyższej konfiguracji jako bazę wybrałem PostgreSQL. Dodatkowo w parametrze ``hibernate.hbm2ddl.auto`` ustawiłem
``create-drop`` dzięki czemu po uruchomieniu będę miał zawsze świeżą bazę zgodną ze schematem mojego modelu.

Aby nie musieć za każdym razem wypełniać bazy jakimiś danymi skorzystamy z triku z plikiem ``import.sql``. Otóż okazuje się, że
jeżeli taki plik znajdzie się na CLASSPATH (w głównym katalogu, nie żadnym pakiecie), to Hibernate wykona polecenia SQL w nim
zawarte (warunkiem jest jednak to, aby każde polecenie było w jednej linii):

{% highlight sql %}
INSERT INTO packages (id, latitude, longitude) VALUES ('1', '53.43', '14.529');
INSERT INTO packages (id, latitude, longitude) VALUES ('2', '50.47', '16.15');
INSERT INTO packages (id, latitude, longitude) VALUES ('3', '50.53', '20.39');
INSERT INTO packages (id, latitude, longitude) VALUES ('4', '52.13', '20.57');
INSERT INTO packages (id, latitude, longitude) VALUES ('5', '49.57', '18.43');
{% endhighlight %}

Teraz możemy przetestować wcześniejsze zmiany (wciąż w konsoli, gdyż jak dotąd aplikacja SPU nie dorobiła się zestawu
testów). Przed testem należy nie zapomnieć o pobraniu odpowiedniego sterownika JDBC (dla bazy PostgreSQL można go
pobrać [stąd](http://jdbc.postgresql.org/download.html)):

{% highlight bash %}
$ curl http://localhost:8080/spu-service/track.xml?packageId=1
<response status="101"><package id="1"><position latitude="53.43" longitude="14.529"/></package></response>
$ curl http://localhost:8080/spu-service/track.xml?packageId=2
<response status="101"><package id="2"><position latitude="50.47" longitude="16.15"/></package></response>
$ curl http://localhost:8080/spu-service/track.json?packageId=2
{"response":{"package":{"id":2,"position":{"latitude":50.47,"longitude":16.15}},"status":101}}
{% endhighlight %}

## Konfiguracja Log4J

Jako, że aplikacja się rozrasta wypadałoby skonfigurować jakiś framework do logowania. W przypadku aplikacji SPU
użyję frameworka Log4J. Jak zwykle całą zabawę należy zacząć od skonfigurowania zależności w pliku ``pom.xml``:

{% highlight xml %}
<dependency>
    <groupId>log4j</groupId>
    <artifactId>log4j</artifactId>
    <version>1.2.16</version>
</dependency>
{% endhighlight %}

Nie musimy wykonywać żadnej dodatkowej konfiguracji w Springu, wystarczy, że na CLASSPATH-u umieścimy plik ``log4j.xml`` z konfiguracją dla
Log4J:

{% highlight xml %}
<log4j:configuration xmlns:log4j="http://jakarta.apache.org/log4j/">

    <appender name="CONSOLE" class="org.apache.log4j.ConsoleAppender">
        <layout class="org.apache.log4j.PatternLayout">
            <param name="ConversionPattern" value="%d [%p] [%t] [%C{1}#%M(%L)]: %m%n" />
        </layout>
    </appender>

    <root>
        <level value="INFO" />
        <appender-ref ref="CONSOLE" />
    </root>

</log4j:configuration>
{% endhighlight %}

Od tej chwili możemy logować zdarzenia, które miały miejsce w aplikacji:

## Podsumowanie

Wsparcie dla mapowania obiektowo-relacyjnego jakie daje nam Spring pozwala szybko skonfigurować warstwę persystencji opartą o JPA.
Dodatkowym atutem jest wykorzystanie standardowych adnotacji JPA zarówno w modelu, jak do wstrzykiwania obiektu ``EntityManager``
lub w razie potrzeby ``EntityManagerFactory``. Dzięki temu w razie potrzeby naszą aplikację możemy wyciągnąć spod kuratury Spring-a i wrzucić do
kontenera EJB.

Skonfigurowanie logowania sprowadziło się do zdefiniowania odpowiedniej zależności i utworzenia pliku ``log4j.xml`` bez potrzeby
dodatkowej konfiguracji w Spring-u.

Kod aplikacji dostępny jest na moim profilu GitHub pod adresem: [http://github.com/michalorman/parcelscout/tree/master/work/spu-service/](http://github.com/michalorman/parcelscout/tree/master/work/spu-service/)