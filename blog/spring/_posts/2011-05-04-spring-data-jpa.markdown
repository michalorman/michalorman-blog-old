---
layout: post
title: Spring Data JPA
description:
keywords: Spring Data JPA Repository QueryDSL
---
Technologia Java nigdy nie szczyciła się jakimś wspaniałym wsparciem
dla baz danych, nie tylko relacyjnych. Nawet JPA, która jest swoją
drogą świetną specyfikacją, wymusza na nas tworzenie całej masy
powtarzalnego kodu. Projektem, który ma na celu m.in. poprawienie tej
sytuacji jest [Spring Data](http://www.springsource.org/spring-data).

Co ciekawe projekt ten ma na celu nie tylko zaoszczędzenie nam paru
linijek powtarzalnego kodu, ale ułatwienie interakcji nie tylko z
relacyjnymi bazami danych, a z popularnymi obecnie innymi metodami
przechowywania danych. Listę wspieranych i planowanych baz danych
znajdziemy na stronie projektu. W tym wpisie mam zamiar na tapetę
wziąść wsparcie dla JPA a następnej kolejności zająć się MongoDB.

# Modele i Repozytoria

Na początek potrzebujemy modelu:

{% highlight java %}
public class Applicant {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;

    private String firstName;

    private String lastName;

    @OneToMany
    private List<Competence> competences;

}
{% endhighlight %}

{% highlight java %}
@Entity
public class Competence {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;

    @Column(unique = true)
    private String name;

}
{% endhighlight %}

Podstawową koncepcją **Spring Data** są repozytoria. To one pozwalają
nam wykonywać operacje na naszych modelach. Co ciekawe, o ile nie
mamy specjalnie wyrafinowanych wymagań, nie będziemy musieli napisać
ani jednego repozytorium. Jedyne co będziemy musieli zdefiniować to
interfejs takiego repozytorium, a o jego implementację zadba dla nas
framework. 

Brzmi trochę magicznie, ale całość jest ekstremalnie prosta. Aby
stworzyć repozytorium musimy jedynie utworzyć interfejs, który
rozszeżać powinien interfejs ``JpaRepository`` (w przypadku Spring
Data JPA dla innych baz będzie to inny interfejs):

{% highlight java %}
public interface ApplicantsRepository extends JpaRepository<Applicant,Long> {}
{% endhighlight %}

{% highlight java %}
public interface CompetencesRepository extends JpaRepository<Competence, Long> {}
{% endhighlight %}

To właściwie tyle jeżeli chodzi o javę. Implementację tych interfejsów zapewni nam **Spring
Data**. Jedyne co jeszcze musimy zrobić, to konfiguracji springowej
powiedzieć, gdzie znajdują się nasze repozytoria:

{% highlight xml %}
<jpa:repositories base-package="pl.michalorman.springdata.jpa.repository" />
{% endhighlight %}

Teraz możemy wstrzykwiać nasze repozytoria do innych komponentów i
korzystać z podstawowych operacji jakie one nam zapewniają. Po szczegóły odsyłam do
[API](http://static.springsource.org/spring-data/data-jpa/docs/current/api/)
ja przejdę od razu do nieco ciekawszych zastosowań repozytoriów.
