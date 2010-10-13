---
layout: post
title: Jeszcze prostsze serwisy webowe z Spring MVC
description: Opis błyskawicznego tworzenia serwisu webowego opartego o framework Spring MVC.
keywords: spring mvc webservice json
---
W kilku ostatnich postach przedstawiłem architekturę serwisu webowego opartego o framework Spring. Otóż okazuje się,
że jeżeli do naszego serwisu nie ma wymagań takich jak negocjowanie formatu odpowiedzi i jasnym jest, że odpowiedź
serwera zawsze jest w formacie Json, tworzenie takiego serwisu staje się jeszcze prostsze. Konfiguracja całej aplikacji
sprowadza się do zadeklarowania kilku adnotacji i doprawdy minimalnej ilości konfiguracji w plikach XML. Oto w kilku
krokach przedstawię jak można szybko i łatwo stworzyć taką aplikację.

## Generowanie projektu webowego

Do wygenerowania projektu wykorzystam oczywiście narzędzie maven, którego wcześniej bardzo nie lubiałem, a teraz nie
wyobrażam sobie pracy bez niego. Aplikację utworzę bez wykorzystywania gotowych archetypów innych niż standardowy
``maven-archetype-webapp`` (od razu zaznaczam, że jeszcze nie zaktualizowałem swojego mavena do 3-ciej wersji).

    $ mvn archetype:create -DarchetypeArtifactId=maven-archetype-webapp -DgroupId=demo.service -DartifactId=demo-service

Projekt gotowy, teraz potrzebujemy dodać zależności:

{% highlight xml %}
<dependencies>                                           
    <dependency>                                         
        <groupId>org.springframework</groupId>           
        <artifactId>spring-webmvc</artifactId>           
        <version>3.0.4.RELEASE</version>
    </dependency>                                        
</dependencies>                                          
{% endhighlight %}

Potrzebujemy oczywiście ``spring-webmvc``. Możemy przystąpić do pracy.

## Konfiguracja i stare podejście do serwisów

Przepływ obsługi żądania w Spring MVC jest prosty jak budowa cepa. Wszystkie żądania trafiają do serwletu
``DispatcherServlet`` (których może być kilka w razie potrzeby), dalej poszukiwany jest odpowiedni kontroler, który
obsłuży żadanie i zwróci obiekty modelu, które następnie są przekazywane komponentowi odpowiedzialnemu za wyrenderowanie
odpowiedzi. Pierwszą rzeczą jaką zatem należy zrobić, to skonfigurowanie serwletu:

{% highlight xml %}
<web-app>                                                                                 
    <servlet>                                                                             
        <servlet-name>demo-service</servlet-name>                                   
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>  
        <load-on-startup>1</load-on-startup>                                              
    </servlet>                                                                            
    <servlet-mapping>                                                                     
        <servlet-name>demo-service</servlet-name>                                   
        <url-pattern>/*</url-pattern>                                                     
    </servlet-mapping>                                                                    
</web-app>                                                                                
{% endhighlight %}

Serwlet mapujemy na wszelkie żądania skierowane do naszej aplikacji. Kolejna rzecz jaką musimy zrobić to utworzyć plik
konfiguracyjny springa. Domyślnie poszukiwany jest plik o nazwie takiej jak nazwa serwletu z końcówką ``-servlet.xml``
zatem w naszym przypadku będzie to ``demo-service-servlet.xml`` (nazwa trochę idiotyczna, ale można ją w prosty sposób
zmienić, a także dodać nowe pliki jeżeli ktoś - tak jak ja - lubi separować konfigurację pomiędzy kilka plików, zamiast
używać jednego meta-pliku konfiguracyjnego). Oczywiście tworzymy go w katalogu ``WEB-INF``:

{% highlight xml %}
<beans xmlns="http://www.springframework.org/schema/beans"               
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"             
       xmlns:context="http://www.springframework.org/schema/context"     
       xsi:schemaLocation="http://www.springframework.org/schema/beans   
       http://www.springframework.org/schema/beans/spring-beans.xsd      
       http://www.springframework.org/schema/context                     
       http://www.springframework.org/schema/context/spring-context.xsd">
                                                                         
    <context:component-scan base-package="demo.service" />               
                                                                         
</beans>                                                                 
{% endhighlight %}

Dobra starczy tego piekła XML-owego, przejdźmy do kodowania. Stwórzmy kontroler:

{% highlight java %}
@Controller                                                                                          
public class ServiceController {                                                                     
                                                                                                     
    @RequestMapping("/service")                                                                      
    public void service(@RequestParam String userId, @RequestParam String serviceId,                 
                        @RequestParam Double price, @RequestParam(required = false) String currency, 
                        Model model) {                                                               
        // obsługa żądania...                                                                        
    }                                                                                                
                                                                                                     
}                                                                                                    
{% endhighlight %}

Tak do tej pory mapowałem parametry żądania na parametry metody je obsługującej. Zwróćmy uwagę, że
parametrów jest raptem 4 a już deklaracja metody wygląda ohydnie. Co by było, gdyby tych parametrów
było powiedzmy 11 (co w cale nie jest takie niespotykane)? Czy nie ma sposobu, aby zenkapsulować
te parametry (oczywiście, że jest inaczej bym nie robił tego wpisu ;))?

## Enkapsulacja parametrów żądania

Z pomocą przychodzi nam [Hibernate Validator](http://www.hibernate.org/subprojects/validator.html) (wraz ze swoim
wsparciem dla specyfikacji JSR-303 czyli Bean Validation). Dodajmy zatem zależność do pliku ``pom.xml``:

{% highlight xml %}
<dependency>                                      
    <groupId>org.hibernate</groupId>              
    <artifactId>hibernate-validator</artifactId>  
    <version>4.0.2.GA</version>                   
</dependency>                                     
{% endhighlight %}

Utwórzmy zatem klasę, która będzie enkapsulować parametry żądania:

{% highlight java %}
public class ServiceRequest {            
                                         
    @NotEmpty                            
    @Pattern(regexp = "\\p{Alnum}{6,16}")
    private String userId;               
                                         
    @NotEmpty                            
    @Pattern(regexp = "\\p{Alnum}{16}")  
    private String serviceId;            
                                         
    @NotNull                              
    private Double price;                
                                         
    @Pattern(regexp = "\\p{Upper}{3}")   
    private String currency;             
                                         
    // gettery & settery ...             
                                         
}                                        
{% endhighlight %}

Czyli mamy zwykłe POJO z adnotacjami deklarującymi nasze ograniczenia co do poprawności poszczególnych
parametrów (takiej deklaratywności nie udałoby się nam osiągnąć w poprzednim podejściu). Aby skorzystać
z powyższych deklaracji musimy zmienić deklarację naszej metody obsługującej żądanie:

{% highlight java %}
@RequestMapping("/service")                                                     
public void service(@Valid ServiceRequest request, BindingResult bindingResult, 
                    Model model) {                                              
    // obsługa żądania...                                                       
}                                                                               
{% endhighlight %}

Zamiast serii parametrów mamy jeden, z adnotacją ``@Valid`` określającą, iż ma na nim zostać przeprowadzona
walidacja (jest to swoją droga konieczne). Dodatkowy parametr ``BidningResult`` jest wymagany i w nim
zostaną zapisane wyniki walidacji (czyli wszelkie komunikaty o błędach umieszczone bądź to bezpośrednio
w adnotacjach, bądź w plikach properties z konfiguracją dla poszczególnych języków). Niestety jakkolwiek
jest to przydatne w przypadku witryn internetowych (gdzie komunikaty o błędach pojawiają się gdzieś przy
odpowiednich polach formularzy) o tyle w przypadku serwisów nie do końca to się sprawdza, gdyż mają one
często specyficzne wymagania dotyczące zwracania komunikatów o błędzie (często jest to jakiś odpowiedni
``statusCode`` z dodatkowym ``statusText``). Dlatego być może będziemy musieli utworzyć własny walidator,
który bardziej będzie odpowiadał naszym wymaganiom (jednak korzystając ze specyfikacji JSR-303 jest to
dziecinnie proste - może w którymś z kolejnych wpisów przedstawię jak to zrobić).

Do działania tego wszystkiego potrzbujemy jeszcze jednej linijki w pliku konfiguracyjnym springa:

{% highlight xml %}
<mvc:annotation-driven />
{% endhighlight %}

## Obiekt jako odpowiedź serwera

Co bardziej spostrzegawczy być może zauważyli, żę nie zadeklarowałem jak dotąd żadnego komponentu, który
byłby odpowiedzialny za wyrenderowanie widoku. Trzeba się jednak zastanowić, czy w ogóle taki komponent
jest nam potrzebny? W końcu i tak nie mamy żadnych stron JSP, czy Spring nie może po prostu wziąść
jakiegoś obiektu i zmapować go na Json-a? Otóż okazuje się, że może, wystarczy dodać jedną adnotację:

{% highlight java %}
@RequestMapping("/service")                                                         
@ResponseBody                                                                       
public Object service(@Valid ServiceRequest request, BindingResult bindingResult) { 
    // obsługa żądania...                                                           
}                                                                                   
{% endhighlight %}

Adnotacja ``@ResponseBody`` poinstruuje Springa, iż ma wziąść obiekt zwrócony przez metodę i użyć go
jako odpowiedzi serwera, przy czym Spring jest na tyle inteligentny, że sam zmapuje obiekt do formatu
Json (jeżeli chcemy, możemy zmienić to domyślne zachowanie i zmapować np. na XML-a). Zauważmy również,
że nie potrzebujemy już więcej parametru ``model``.

Potrzebujemy jeszcze dodać zależność do frameworka, który zajmie się faktycznym zadaniem serializacji
klasy (jako, że Spring sam z siebie tego nie zrobi):

{% highlight xml %}
<dependency>                                    
    <groupId>org.codehaus.jackson</groupId>     
    <artifactId>jackson-mapper-asl</artifactId> 
    <version>1.6.0</version>                    
</dependency>                                   
{% endhighlight %}

Terez nie pozostaje nam nic innego, jak zaimplementowanie jakiejś logiki, celem przetestowania, ale
to pozostawiam już jako pracę domową ;).
