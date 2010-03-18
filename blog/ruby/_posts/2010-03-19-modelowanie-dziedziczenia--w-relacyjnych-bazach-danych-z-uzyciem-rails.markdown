---
layout: post
title: Modelowanie dziedziczenia w relacyjnych bazach danych z użyciem Rails
description: Relacyjne bazy danych nie udostępniają możliwości modelowania dziedziczenia. Istnieją jednak pewne strategie pozwalające symulować ten paradygmat w relacyjnych bazach danych.
keywords: Rails STI Single Table Inheritance Table per Hierarchy concrete class polymorphic association
navbar_pos: 1
---
Relacyjne bazy danych, jak nazwa wskazuje, służą do modelowania relacji i nie udostępniają możliwości dziedziczenia. Istnieje
jednak kilka strategii pozwalających symulować ten paradygmat w ich środowisku. Te strategie to:

* Jedna tabela dla całej hierarchii dziedziczenia (ang. table per hierarchy), zwana także STI (ang. Single Table Inheritance).
* Jedna tabela dla każdej *konkretnej* klasy (ang. table per concrete class).
* Jedna tabela dla każdej klasy (ang. table per class).
* Schemat generyczny (ang. generic schema).

Pełny opis strategii wraz z diagramami można znaleźć [tutaj](http://www.agiledata.org/essays/mappingObjects.html#MappingInheritance).

Platforma Java EE wspiera pierwszą i trzecią strategię dziedziczenia (z czego trzecią strategię w dwóch odmianach
[JOINED](http://openjpa.apache.org/builds/1.0.2/apache-openjpa-1.0.2/docs/manual/jpa_overview_mapping_inher.html#jpa_overview_mapping_inher_joined)
oraz [TABLE_PER_CLASS](http://openjpa.apache.org/builds/1.0.2/apache-openjpa-1.0.2/docs/manual/jpa_overview_mapping_inher.html#jpa_overview_mapping_inher_tpc)).
W przypadku frameworka Rails mamy do dyspozycji jedynie STI.

Zanim zaczniemy zmuszać nasze relacyjne bazy danych do wspierania dziedziczenia musimy upewnić się, że jest nam to
niezbędne. Dziedziczenie to jeden z najmocniejszych czynników wiążących klasy (ang. coupling) i generalnie powinniśmy
z niego korzystać tylko wtedy, jeżeli spodziewamy się polimorficznego wykorzystywania obiektów. W przeciwnym razie wystarczy
nam zwyczajna agregacja i delegacja. Nie jest dobrym argumentem także to, że operacje na STI są szybsze, ponieważ
eliminują potrzebę łączenia tabel. Ogólnie optymalizacją powinniśmy się zajmować **tylko i wyłącznie** wtedy, kiedy
mamy problem z wydajnością. W każdym innym przypadku należy stosować pierwszą zasadę optymalizacji - "nie rób tego".

## Single Table Inheritance

Zatem jesteśmy pewni tego, że dziedziczenie modeli jest nam niezbędne. Rails umożliwia nam zamodelowanie dziedziczenia
z wykorzystaniem [Single Table Inheritance](http://en.wikipedia.org/wiki/Object-relational_mapping). Dlaczego tylko
ta strategia? Ano dlatego, że framework Rails promuje proste rozwiązania, a STI to najprostsze rozwiązanie.

Czym zatem jest STI? Mianowicie strategia ta zakłada, że dla całej naszej hierarchii dziedziczenia tworzymy jedną tabelę,
która agreguje wszelkie atrybuty z wszystkich encji wchodzących w skład drzewa dziedziczenia. Zobaczmy jak to wygląda na
przykładzie.

Załóżmy, że wśród użytkowników naszego systemu wyróżniamy klientów systemu, oraz administratorów. Wśród klientów możemy
mieć zarówno osoby prywatne jak i firmy. Hierarchia dziedziczenia jest prosta, wychodzimy od klasy ``User`` po której
dziedziczą klasy ``Customer`` oraz ``Admin`` natomiast po klasie ``Customer`` dziedziczą ``Person`` oraz ``Company``:

<a href="/images/sti_hierarchy.png" title="Hierarcha dziedziczenia" rel="colorbox"><img src="/images/sti_hierarchy.png" alt="Hierarchia dziedziczenia" /></a>

Kluczem do zamodelowania tej hierarchii jest odpowiednia migracja. Ponieważ cała hierarchię będziemy modelować w jednej
tabeli oczywistym jest, że będzie to tabela ``users``. Migracja dla takiej tabeli przedstawiać się będzie następująco:

{% highlight ruby %}
class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      # Wymagane przez STI
      t.string :type

      # atrybuty modelu User
      t.string :username
      t.string :password

      # atrybuty modelu Person
      t.string :first_name
      t.string :last_name

      # atrybuty modelu Company
      t.string :company_name
      t.string :tax_id

      # atrybuty modelu Admin
      t.string :email

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
{% endhighlight %}

W powyższej migracji wymagana jest kolumna ``type``, którą Rails wykorzystuje do określania jakiemu typowi (klasie) odpowiada dany rekord.
Pozostałe kolumny reprezentują atrybuty poszczególnych modeli. Teraz kilka testów. Utwórzmy rekord dla modelu ``Person``:

{% highlight irb %}
>> Person.create(:first_name => 'Jan', :last_name => 'Kowalski')
=> #<Person id: 1, type: "Person", username: nil, password: nil, first_name: "Jan", last_name: "Kowalski", company_name: nil, tax_id: nil, email: nil, created_at: "2010-03-18 19:19:25", updated_at: "2010-03-18 19:19:25">
{% endhighlight %}

Sprawdźmy co siedzi w naszej bazie:

{% highlight irb %}
>> User.all
=> [#<Person id: 1, type: "Person", username: nil, password: nil, first_name: "Jan", last_name: "Kowalski", company_name: nil, tax_id: nil, email: nil, created_at: "2010-03-18 19:19:25", updated_at: "2010-03-18 19:19:25">]
>> Person.all
=> [#<Person id: 1, type: "Person", username: nil, password: nil, first_name: "Jan", last_name: "Kowalski", company_name: nil, tax_id: nil, email: nil, created_at: "2010-03-18 19:19:25", updated_at: "2010-03-18 19:19:25">]
{% endhighlight %}

Dalej stwórzmy rekord dla modelu ``Company``:

{% highlight irb %}
>> Company.create(:company_name => 'Soft Ltd.', :tax_id => '123456789')
=> #<Company id: 2, type: "Company", username: nil, password: nil, first_name: nil, last_name: nil, company_name: "Soft Ltd.", tax_id: "123456789", email: nil, created_at: "2010-03-18 19:20:29", updated_at: "2010-03-18 19:20:29">
{% endhighlight %}

I ponownie sprawdźmy stan bazy:

{% highlight irb %}
>> User.all
=> [#<Person id: 1, type: "Person", username: nil, password: nil, first_name: "Jan", last_name: "Kowalski", company_name: nil, tax_id: nil, email: nil, created_at: "2010-03-18 19:19:25", updated_at: "2010-03-18 19:19:25">, #<Company id: 2, type: "Company", username: nil, password: nil, first_name: nil, last_name: nil, company_name: "Soft Ltd.", tax_id: "123456789", email: nil, created_at: "2010-03-18 19:20:29", updated_at: "2010-03-18 19:20:29">]
>> Person.all
=> [#<Person id: 1, type: "Person", username: nil, password: nil, first_name: "Jan", last_name: "Kowalski", company_name: nil, tax_id: nil, email: nil, created_at: "2010-03-18 19:19:25", updated_at: "2010-03-18 19:19:25">]
>> Company.all
=> [#<Company id: 2, type: "Company", username: nil, password: nil, first_name: nil, last_name: nil, company_name: "Soft Ltd.", tax_id: "123456789", email: nil, created_at: "2010-03-18 19:20:29", updated_at: "2010-03-18 19:20:29">]
>> Customer.all
=> [#<Person id: 1, type: "Person", username: nil, password: nil, first_name: "Jan", last_name: "Kowalski", company_name: nil, tax_id: nil, email: nil, created_at: "2010-03-18 19:19:25", updated_at: "2010-03-18 19:19:25">, #<Company id: 2, type: "Company", username: nil, password: nil, first_name: nil, last_name: nil, company_name: "Soft Ltd.", tax_id: "123456789", email: nil, created_at: "2010-03-18 19:20:29", updated_at: "2010-03-18 19:20:29">]
>> Admin.all
=> []
{% endhighlight %}

Zasadniczo to jest wszystko co trzeba zrobić, aby zamodelować hierarchię dziedziczenia zgodnie ze strategią STI. Jednakże
prostota ta ma swoją cenę. Jak widać po powyższych wynikach wszystkie rekordy posiadają wszystkie kolumny (co jest raczej
oczywiste ;)), jednakże kolumny przekładają się na atrybuty modeli:

{% highlight irb %}
>> Person.create(:company_name => 'Macro Corp')
=> #<Person id: 3, type: "Person", username: nil, password: nil, first_name: nil, last_name: nil, company_name: "Macro Corp", tax_id: nil, email: nil, created_at: "2010-03-18 20:28:59", updated_at: "2010-03-18 20:28:59">
>> Person.all
=> [#<Person id: 1, type: "Person", username: nil, password: nil, first_name: "Jan", last_name: "Kowalski", company_name: nil, tax_id: nil, email: nil, created_at: "2010-03-18 19:19:25", updated_at: "2010-03-18 19:19:25">, #<Person id: 3, type: "Person", username: nil, password: nil, first_name: nil, last_name: nil, company_name: "Macro Corp", tax_id: nil, email: nil, created_at: "2010-03-18 20:28:59", updated_at: "2010-03-18 20:28:59">]
>> Person.find(1).company_name
=> nil
>> Person.find(3).company_name
=> "Macro Corp"
{% endhighlight %}

Oczywiście możemy walczyć z tym, ale trzeba zadać sobie pytanie, czy jest to naprawdę taki problem? Generalnie możemy liczyć,
że wszyscy programiści biorący udział w projekcie i w miarę ogarniający biznes aplikacji nie będą udostępniać w formularzu
rejestrowania osoby pola z nazwą firmy. A nawet jeżeli już to łatwo to można znaleźć w testach (a w logach commitów znaleźć
winowajcę ;)). Wbrew pozorom nie sprawia to takich problemów podobnie jak wiele rzeczy znanych z języków dynamicznych, a których
obawiają się programiści innych języków. W przypadku STI i Rails chodzi o prostotę implementacji.

Powyższa cecha ma jeszcze inne implikacje. Po pierwsze, żadna kolumna nie może mieć ograniczenia ``NOT NULL``. Może to być
wymuszone na modelu, ale nie na bazie ponieważ inne modele dziedziczące muszą mieć możliwość ustawienia kolumny na ``NULL``,
dla kolumn, które nie należą do modelu. Po drugie żadne dwa modele z jednej hierarchii nie
mogą posiadać atrybutów o tej samej nazwie a innych typach, ponieważ oba te atrybuty są mapowane na jedną kolumnę.

## Podsumowanie

Framework Rails stawia na prostotę jeżeli chodzi o modelowanie dziedziczenia w relacyjnych bazach danych, stąd jedyną
domyślnie dostępną strategią jest Single Table Inheritance (Single Table per Hierarchy). Generalnie potrzeba stosowania
takiej ekwilibrystyki jest dość rzadka i powinna być dobrze przemyślana. Dziedziczenie powinno mieć miejsce tylko w przypadku
w którym spodziewamy się wykorzystania polimorfizmu, w przeciwnym razie powinniśmy stosować agregacje, które luźniej
wiążą klasy. Samo zamodelowanie STI jest dziecinnie proste i sprowadza się do utworzenia odpowiedniej migracji
(plus oczywiście zamodelowania samego dziedziczenia modeli). Prostota ta ma jednak pewne swoje ograniczenia.

Rails udostępnia jeszcze inny sposób pozwalający w polimorficzny sposób traktować kolumny, jednakże nie jest on dziedziczeniem. Tym sposobem jest
tzw. **Polymorphic Associations** czyli w wolnym tłumaczeniu polimorficzne asocjacje. Mechanizm ten przedstawię
w którymś z kolejnych wpisów.