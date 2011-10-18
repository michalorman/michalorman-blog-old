---
layout: post
title: Unobtrusive CSS
description: Nie tylko JavaScript powinien być unobtrusive.
keywords: Unobtrusive CSS ruby SCSS SASS
---
Bardzo modnym ostatnio terminem jest [Unobtrusive JavaScript
](http://en.wikipedia.org/wiki/Unobtrusive_JavaScript). Ideą tego
podejścia jest nie umieszczanie wywołań JavaScript w plikach HTML
(np. w zdarzeniach `onclick` czy `onblur`) a przypinanie ich z poziomu
samych JavaScriptów za pomocą odpowiednich selektorów (a jeszcze lepiej
z wykorzystaniem np. [jQuery](http://jquery.com/)). Mało jednak się
mówi iż ten sam paradygmat tyczy się CSS-a, a w jego przypadku sprawa
jest trochę mniej oczywista.

Zacznijmy od trywialnego przykładu, na początek w Javie, a konkretniej
JSF. Któż z nas nie spotkał się z czymś podobnym:

{% highlight xml %}
<ice:panelGrid columns="3" style="width:100%" cellpadding="0" cellspacing="0"
               columnClasses="col15 firstcol, col35 lastcol, col50 lastcol">

    <!-- ... -->

</ice:panelGrid>
{% endhighlight %}

Jaki jest sens tworzenia klas typu `col50`? Czym to się różni od
ustawienia `style="width: 50%"` prosto w plikach JSF? Oczywiście w przypadku JSF i
komponentu `panelGrid` nie da się ustawić stylu dla poszczególnych
kolumn, A jedynie klasy, ale niewiele to zmienia.

Przejdźmy jednak do mniej oczywistego przypadku, na który ja się
ostatnio złapałem. Tworzyłem formularz, który w odróżnieniu od
pozostałych, zamiast każde pole renderować w kolejnym wierszu cały
renderował się w jednym. Pomyślałem, tak jak pewnie wiele osób by
pomyślało, zrobię klasę `inline-form`. Wtedy do każdego formularzu,
który ma być renderowany "w linii" dodam tę klasę i będzie śmigać. No i
powstał taki kod:

{% highlight haml %}
= simple_form_for @language, :html => { class: 'inline-form' } do |f|
  = f.input :name, :label => false
  = f.input :level, :label => false
  = f.submit
{% endhighlight %}

I arkusz styli:

{% highlight css %}
.inline-form {
  overflow: hidden;
  input {
    float: left;
  }
}
{% endhighlight %}

W arkuszu stylów standard, jakiś float, jakiś overflow.

Im dłużej się przyglądałem temu formularzowi tym bardziej mi się to
przestawało podobać. Czym to się właściwie różni od "niesławnych"
`col35` czy `col50` z poprzedniego przykładu? Idea jest
dokładnie ta sama. Jakiś fragment CSS-a zamykamy w klasie i ją
umieszczamy w HTML-u. Po prostu mamy mniej klepnięć w klawiaturę, no i
reużycie kodu prawda?

Style powinniśmy w dokumentach HTML umieszczać w sposób
unobtrusive. Aby to osiągnąć, podobnie jak w przypadku JavaScript-u,  powinniśmy w arkuszu stylów odpowiednim
selektorem wybrać interesujący nas formularz i zdefiniować jak on
powinien wyglądać. Nie potrzebujemy żadnej klasy.

Niestety sam CSS jest zbyt ograniczony, aby osiągnąć ten efekt
jednocześnie nie duplikując kodu. Jeżeli chcielibyśmy
posiadać wiele takich formularzy musielibyśmy skopiować kod
stylu dla każdego formularza. Dlatego warto zamiast czystego CSS-a skorzystać z takich
języków jak
[Sass](http://en.wikipedia.org/wiki/Sass_(stylesheet_language)). W
Sass możemy bardzo łatwo osiągnąć ten sam efekt bez dublowania kodu:

{% highlight sass %}

@mixin inline-form {
  overflow: hidden;
  input {
    float: left;
  }
}

#new_language {
  @include inline-form;
}

{% endhighlight %}

Po co ta cała zabawa? Po to aby nie mieszać odpowiedzialności
([SRP](http://en.wikipedia.org/wiki/Single_responsibility_principle)?).
HTML mówi co znajduje się w dokumencie, CSS określa jak wygląda a
JavaScript jak się zachowuje. Zarówno JavaScript jak i CSS powinny być
łączone z dokumentem HTML w sposób unobtrusive.
