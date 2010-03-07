---
layout: post
title: Masowe przypisania i inne dziury w aplikacjach Rails
description: Najczęstsze błędy bezpieczeństwa popełniane podczas tworzenia aplikacji w Rails. Jak ich unikać i jak programować bezpiecznie.
keywords: ruby rails security masowe przypisania mass assignment attr_protected
navbar_pos: 1
---
Dzisiaj natrafiłem na [znakomity wpis](http://b.lesseverything.com/2008/3/11/use-attr_protected-or-we-will-hack-you)
dotyczący błędów popełnianych podczas tworzenia aplikacji railsowych. Uważam, że
u każdego programisty bezpieczeństwo systemu powinno mieć bardzo wysoki priorytet,
toteż pozwoliłem sobie skorzystać z wiedzy zawartej w owym wpisie i przedstawić
problem na moim blogu.

Gdzie zatem mogą się kryć niebezpieczeństwa w naszych aplikacjach railsowych? Najpierw
przyjrzyjmy się poniższej komendzie:

<pre>
curl -d “user[login]=hacked&user[is_admin]=true&user[password]=password&user[password_confirmation]=password&user[email]=hacked@by.me” http://url_not_shown/users
</pre>

Przyjrzyjcie się uważnie i skonfrontujcie to z waszymi aplikacjami. Coś mi się
wydaje, że w wielu przypadkach ta komenda pozwoli na stworzenie użytkownika z prawami
administratora, a to bardzo poważna luka w bezpieczeństwie systemu.

Niebezpieczeństwo bierze się niejaka z tego, co uważane jest za jedną z najlepszych
cech frameworka Rails, czyli konfiguracji przez konwencję (ang. convention over
configuration). (A ta się wzięła niejako z lenistwa programistów, ale który z nas
nie jest leniwy i nie lubi ułatwiać sobie kodowania :)).

## Masowe przypisania

Masowe przypisania (ang. mass assignments) to jedna z fajniejszych rzeczy i w
języku Ruby jak i w frameworku Rails. Jednakże jednocześnie jest to główny powód
potencjalnych luk bezpieczeństwa w systemie. Rzućmy okiem na poniższy kod:

{% highlight ruby %}
class UsersController < ApplicationController

  def create
    @user = User.create(params[:user])
  end

end
{% endhighlight %}

Kod ten jest bardzo często używany  w aplikacjach railsowych (ewentualnie zamiast metody `create()`
wywoływana jest metoda `new()`). To co Rails za nas zrobi to zamapuje
wszelkie parametry występujące w żądaniu dla formularza `user` na odpowiednie
składowe klasy `User`. Problem polega na tym, że w tym wywołaniu o atrybutach, którym
zostaną nadane wartości **decyduje
żądanie**, a co za tym idzie użytkownik, który je wygenerował! Jest to poważna luka
w zabezpieczeniach! Nie można pozwolić użytkownikowi na manipulowanie formatem danych
ani tym jakie dane zostaną w konkretnym żądaniu zapisane. Prawidłowy i bezpieczny kod
powinien wyglądać tak:

{% highlight ruby %}
class UsersController < ApplicationController

  def create
    @user = User.new
    @user.login = params[:user][:login]
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    @user.save!
  end

end
{% endhighlight %}

W tym kodzie to programista decyduje, którym atrybutom klasy `User` zostaną nadane
wartości, a co za tym idzie nie ma niebezpieczeństwa, że ktoś przemyci jakieś dane
w parametrach żądania. Nie ma także niebezpieczeństwa, że jak ktoś zapomni zabezpieczyć
jakieś pole to niecny użytkownik to wykorzysta. Po prostu tylko te wybrane pola
zostaną ustawione, bo tylko takie występują w formularzu.

Tutaj jest przykład dla kontrolera użytkowników, jednak jest to także problem
w przypadku innych kontrolerów. O ile nie będzie to miało tak niebezpiecznych
konsekwencji (jakiś nieuprawniony użytkownik nie otrzyma dostępu do zasobów), może on
w pewien sposób manipulować naszymi danymi. Dla bezpieczeństwa lepiej nie pozostawiać
użytkownikom wyboru jakie dane mogą być w konkretnym żądaniu zapisane.

## Dostępność i ochrona atrybutów

Rails udostępnia nam dwie dyrektywy pozwalające nam odpowiednio chronić atrybuty
naszego modelu. Są to:

* `attr_protected`, oraz
* `attr_accessible`

Pierwsza dyrektywa pozwala nam na wylistowanie atrybutów, które nie będą uwzględniane
podczas masowego przypisania. Na przykład możemy oznaczyć nim atrybut `is_admin`:

{% highlight ruby %}
class User < ActiveRecord::Base

  attr_protected :is_admin

end
{% endhighlight %}

Railsy zagwarantują nam, że atrybut `is_admin` nie zostanie przypisany nawet jeżeli taki parametr wystąpi
w żądaniu. Jeżeli, chcemy go ustawić musimy zrobić to ręcznie.

Podejście to może jednak spowodować, że od czasu do czasu ktoś
zapomni dodać do listy jakiś atrybut i narazi nasz system na kompromitację. Dlatego
Railsy udostępniają dyrektywę `attr_accessible`. O ile `attr_protected` działają na zasadzie
*black-listy* o tyle `attr_accessible` działa na zasadzie *white-listy*. Tylko atrybuty
wymienione w dyrektywie będą uwzględnione w masowym przypisaniu. Np:

{% highlight ruby %}
class User < ActiveRecord::Base

  attr_accessible :login, :email, :password, :password_confirmation

end
{% endhighlight %}

W tym przypadku tylko te wymienione atrybuty będą uwzględniane w masowym przypisaniu. Jest to o tyle bezpieczniejsze,
że nie ryzykujemy luki w zabezpieczeniach jeżeli ktoś zapomni dodać atrybut do listy, najwyżej
nie będzie działać mu funkcjonalność (a problem powinien wyjść w testach).

Wydaje się, że owe dyrektywy `attr_protected` oraz `attr_accessible`
rozwiązują nam problemy z masowym przypisaniem. Jednakże moim zdaniem nie jest tak
do końca. W przypadku `attr_protected` ktoś może zapomnieć dodać jakiś atrybut do listy
natomiast w przypadku `attr_accessible` ktoś nieuważnie może dodać o jeden atrybut
za dużo, co pozwoli hakerom w niekontrolowany sposób manipulować naszymi danymi.
Uważam, że odrobina wysiłku włożona w rezygnację z masowego przypisania opłaci
się poprzez lepsze zabezpieczenie naszego systemu. Jak dla mnie jest to cena, którą
warto zapłacić.