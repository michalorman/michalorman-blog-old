---
layout: post
title: Spinner z Simple Form
description: ruby rails simple_form spinner
keywords: Spinner z Simple Form ruby
---
Załóżmy, że w naszej aplikacji tworzymy widok na którym zawartość
jednej listy wyboru zmienia się w zależności od tego co wybierzemy w
drugiej. Opcje listy przeładowywane są oczywiście z pomocą AJAX-a. Załóżmy
również, że chcemy użytkownika poinformować o owym żądaniu
wyświetlając odpowiedni obrazek postępu (tzw. spinner) tuż obok listy,
która ma zostać przeładowana. Oczywiście nic nie powinno stać na
przeszkodzie, aby takich list mieć wiele na jednym formularzu. Na
koniec załóżmy, że aplikację tworzymy w frameworku Rails z użyciem
[simple_form](https://github.com/plataformatec/simple_form). Jak zatem
dodać spinner to pola formularza? Okazuje się, że korzystając z 
[tej instrukcji](https://github.com/plataformatec/simple_form/wiki/Adding-custom-input-components)
jest to niezwykle proste.

To co chciałbym osiągnąć, to aby nasz spinner można było deklaratywnie
dodawać do pola formularza (podobnie jak pozostałe komponenty):

{% highlight ruby %}
f.association :subcategory, :spinner => true
{% endhighlight %}

Zatem podążając zgodnie z instrukcją modyfikujemy najpierw
konfigurację ``/config/initializers/simple_form.rb``:

{% highlight ruby %}
SimpleForm.setup do |config|
  config.components = [ :placeholder, :label_input, :spinner, :hint, :error ]
end

require 'simple_form/spinner'
{% endhighlight %}

W konfiguracji tej musimy dodać nowy komponent ``spinner`` który będzie
renderowany dla każdego pola formularza.

Następnie tworzymy plik ``/lib/simple_form/spinner.rb``:

{% highlight ruby %}
module SimpleForm
  module Components
    module Spinner
      def spinner
        if options[:spinner]
          spinner_tag(attribute_name)
        end
      end

      private
      
      def spinner_tag(attribute)
        template.image_tag 'spinner.gif', :id => "#{attribute}-spinner", :class => "spinner", :style => "display: none"
      end
    end
  end

  module Inputs
    class Base
      include SimpleForm::Components::Spinner
    end
  end
end
{% endhighlight %}

I to w zasadzie tyle. W metodzie ``spinner`` dla każdego pola, które
posiada opcję ``spinner = true`` tworzymy ``spinner_tag``, który jest
zwyczajnym obrazkiem z unikalnym identyfikatorem. Spinner domyślnie
jest ukryty i musimy go przy odpowiednim zdarzeniu (np. zmianie
nadrzędnej  listy) wyświetlić (np. metodą ``toggle`` z jQuery). Moduł
``Spinner`` musimy jeszcze dołączyć do klasy
``SimpleForm::Inputs::Base`` skąd będzie dostępny dla wszystkich pól
formularza.

Gotowy skrypt jest dostępny tutaj:
[https://github.com/michalorman/simple_form_spinner](https://github.com/michalorman/simple_form_spinner).

Jest w nim też kilka drobnych usprawnień konfiguracyjnych.
