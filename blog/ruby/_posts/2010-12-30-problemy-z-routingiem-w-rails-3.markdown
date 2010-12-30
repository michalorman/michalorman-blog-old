---
layout: post
title: Problemy z routingiem w Rails 3
description: Jak poradzić sobie z routingiem w Rails 3.
keywords: Problemy z routingiem w Rails 3 Ruby
---
Bawiąc się aplikacją pisaną z użyciem frameworka Rails 3.0.3 natknąłem się na irytujący problem, który
wydaje się być błędem w tymże frameworku. Załóżmy, że tak jak ja, nie jesteś fanem przereklamowanych
RESTful-owych routingów (które może nadają się na aplikacje typu blog, ale już na portal społecznościowy
niekoniecznie) możesz na przykład w ten sposób chcieć skonfigurować routing:

{% highlight ruby %}
get 'profile/edit-personal-data' => 'users#edit_personal_data', :as => 'edit_personal_data'
post 'profile/edit-personal-data' => 'users#save_personal_data', :as => 'save_personal_data'
{% endhighlight %}

Formularz dla akcji ``edit_personal_data`` będzie wyglądał następująco (tutaj korzystam z gem'ów
[simple_form](https://github.com/plataformatec/simple_form) oraz [haml](http://haml-lang.com/)):

{% highlight haml %}
= simple_form_for @user, :url => save_personal_data_path do |f|
  = f.input :first_name
  = f.input :last_name
  = f.button :submit
{% endhighlight %}

Kiedy jednak spróbujesz zapisać zmiany wprowadzone w formularzu może spotkać cię niemiła niespodzianka:

{% highlight bash %}
Started POST "/profile/edit-personal-data" for 127.0.0.1 at 2010-12-30 18:53:08 +0100

ActionController::RoutingError (No route matches "/profile/edit-personal-data")
{% endhighlight %}

Sprawdzając routing za pomocą narzędzia rake wszystko wydaje się być w należytym porządku:

{% highlight bash %}
 $ rake routes | grep edit-personal-data
    edit_personal_data GET    /profile/edit-personal-data(.:format)                   {:controller=>"users", :action=>"edit_personal_data"}
    save_personal_data POST   /profile/edit-personal-data(.:format)                   {:controller=>"users", :action=>"save_personal_data"}
{% endhighlight %}

Co więcej, jeżeli zmienić deklarację formularza na:

{% highlight haml %}
= simple_form_for :user, :url => save_personal_data_path do |f|
  ...
{% endhighlight %}

Routing będzie działał prawidłowo, jednak nie będziemy mieli dostępu do samego rekordu zwróconego
z kontrolera, przez co ``simple_form`` nie odczyta prawidłowo naszych walidacji i komunikatów o błędach.

Co jest zatem nie tak z routingiem w Rails 3? Otóż okazuje się, że problem nie tkwi w samym routingu,
ale w wygenerowanym kodzie HTML dla formularza:

{% highlight html %}
<form method="post" id="edit_user_2" class="simple_form user" action="/profile/edit-personal-data" accept-charset="UTF-8">
    <div style="margin: 0pt; padding: 0pt; display: inline;">
        <input type="hidden" value="✓" name="utf8">
        <input type="hidden" value="put" name="_method">
        <input type="hidden" value="XubU7kQVMvI0Q7CEGr7BxhqflmU3iQ2ys+9bT14iclc=" name="authenticity_token">
    </div>
    ...
</form>
{% endhighlight %}

Widzimy, że jednym z ukrytych pól jest to o nazwie ``_method``, którego wartość wynosi ``put`` co oznacza, że mimo iż
faktycznym żądaniem HTTP będzie POST Rails zinterpretuje je jako PUT (jest to taki sposób wsparcia Rails dla innych metod
HTTP niż GET i POST). Rails generuje te ukryte pole dla każdego rekordu, który nie jest nowym rekordem jako, że PUT jest
preferowanym żądaniem do aktualizowania rekordów. To samo jest generowane nawet dla nie-RESTful-owych routingów. Zatem, aby
nasz formularz działał poprawnie musimy dokonać następującej modyfikacji formularza:

{% highlight haml %}
= simple_form_for @user, :url => save_personal_data_path, :html => { :method => :post } do |f|
  = f.input :first_name
  = f.input :last_name
  = f.button :submit
{% endhighlight %}

W tej sytuacji pole ``_method`` nie będzie renderowane. Oczywiście moglibyśmy zmienić nasz routing na ``put`` zamiast ``post``
co również by zadziałało.
