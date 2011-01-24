---
layout: post
title: Niestandardowe typy pól w simple_form
description: Jak prosto dodać nowy typ pola formularza korzystając z frameworka simple_form
keywords: ruby rails simple_form input form pole formularz typ string text zip zip_code input HTML5
---
Standard HTML5 definiuje nam [nowe](http://www.w3schools.com/html5/att_input_type.asp) wartości atrybutu
``type`` dla elementu ``<input>``. Na podstawie wartości tego pola przeglądarki mogą w odpowiedni sposób
renderować pola formularzy. Ma to jeszcze większe znaczenie dla urządzeń mobilnych, gdzie poza samym
polem urządzenia te mogą dostosować wygląd klawiatury za pomocą której wprowadzamy dane.

Po co w ogóle dodawać niestandardowe typy? Ano taki typ możemy
wykorzystać w selektorach czy to w CSS czy w JavaScript'cie (np. korzystając z jQuery). Dzięki temu możemy
sami zdefinować tzw. *look-and-feel* takiego pola. Dlaczego nie użyć w tym przypadku zwyczajnej klasy? Ano, to
że dana wartość atrybutu ``type`` teraz jest niestandardowa nie oznacza, że w przyszłości taką się nie stanie ;).

Zatem co jeżeli chcemy dodać typ niestandardowy korzystając z gem'a [``simple_form``](https://github.com/plataformatec/simple_form)
(i oczywiście frameworka Rails ;))? Najszybszym rozwiązaniem może być użycie parametru ``:as``:

{% highlight haml %}
f.input :zip, :as => :zip_code
{% endhighlight %}

Rozwiązanie to działa, ale ma jedną zasadniczą wadę musimy pamiętać, aby w każdym formularzu dodawać ten
atrybut. ``simple_form`` pozwala nam jednak skonfigurować to sprytniej.

Budowaniem formularza w zajmuje się obiekt ``SimpleForm::FormBuilder`` natomiast samymi polami obiekty
typu ``SimpleForm::Inputs::*``. Gem ten definiuje nam już kilka takich komponentów i możemy skorzystać z nich
do renderowania pola o naszym typie. Jedyne co musimy zrobić to dodać odpowiednie mapowanie (typu na komponent
go renderujący):

{% highlight ruby %}
SimpleForm::FormBuilder.send(:map_type, :zip, :zip_code, :to => SimpleForm::Inputs::StringInput)
{% endhighlight %}

Instrukcję tą możemy dodać np. w pliku ``lib/simple_form_ext.rb`` a następnie zaimportować go w ``config/application.rb``.

Mamy zatem skonfigurowany mapping typów ``zip`` oraz ``zip_code`` na komponent, który je wyrenderuje. Pozostaje
jeszcze jedna kwestia, skąd ``simple_form`` ma wiedzieć, że dany atrybut modelu należy wyrenderować jako typ ``zip_code``?

Okazuje się, że gem ten w inteligentny sposób wykorzystuje konwencje nazewnicze. Jeżeli atrybu posiada w nazwie
email to zostanie wyrenderowany z typem ``email``, jeżeli posiada ``phone`` to zostanie wyrenderowany z typem ``tel``
itd. Co jeszcze lepsze owe mapowanie jest konfigurowalne! Musimy jedynie dodać do konfiguracji gema następującą instrukcję:

{% highlight ruby %}
SimpleForm.setup do |config|
  # (...)
  config.input_mappings = { /zip/ => :zip_code }
  # (...)
end
{% endhighlight %}

Od tego momentu jeżeli atrybut modelu będzie miał w nazwie ``zip`` będzie traktowany jako typ ``zip_code``, a dla tego
typu zamapowaliśmy komponent ``SimpleForm::Inputs::StringInput``, który ma go wyrenderować. Proste! Oto jak działa to
w praktyce, dla:

{% highlight haml %}
f.input :zip
{% endhighlight %}

Dostaniemy:

{% highlight html %}
<div class="input string zip_code optional">
  <label for="address_zip" class="zip_code optional"> Kod pocztowy:</label>
  <input type="zip_code" size="30" name="address[zip]" maxlength="255" id="address_zip" class="string zip_code optional">
</div>
{% endhighlight %}

Od teraz możemy korzystać z selektora ``input[type="zip_code"]`` w naszych CSS'ach lub JS'ach.

Rozwiązanie to jest już dobre, ale nie jest pozbawione wad. Zauważmy, że w wyrenderowanym HTML-u element ``<input>`` posiada
atrybuty ``size`` oraz ``maxlength``. Atrybuty te wzięły sią stąd, że komponent ``StringInput`` takie dodaje do pól o typie
``text``. Rozwiązaniem tego problemu byłoby utworzenie własnego komponentu renderującego, w którym precyzyjnie określilibyśmy
jakie atrybuty mają być w wyrenderowanym HTML-u. Przykładowo taki komponent mógłby wyglądać tak:

{% highlight ruby %}
module SimpleForm
  module Inputs
    class ZipCodeInput < Base
      def input
        input_html_options[:maxlength] ||= 6
        input_html_options[:type] ||= "zip_code"
        @builder.text_field(attribute_name, input_html_options)
      end
    end
  end
end

SimpleForm::FormBuilder.send(:map_type, :zip, :zip_code, :to => SimpleForm::Inputs::ZipCodeInput)
{% endhighlight %}

W wyniku otrzymamy następujący HTML:

{% highlight html %}
<div class="input zip_code optional">
  <label for="address_zip" class="zip_code optional"> Kod pocztowy:</label>
  <input type="zip_code" value="74-500" size="6" name="address[zip]" maxlength="6" id="address_zip" class="zip_code optional">
</div>
{% endhighlight %}

Po tej zmianie nasz HTML wygląda porządnie. Określamy nawet limit 6-ciu znaków dla kodu pocztowego. Nie musimy się też martwić o to
czy dane pole zostanie wyrenderowane z odpowiednim typem, byle tylko atrybut modelu miał w swojej nazwie ``zip``.

Teraz tylko czekać aż ktoś napisze plugin do jQuery, który dla pól o typie ``zip_code`` wyświetlać będzie mapkę google i zamiast wpisywać kod będziemy
go sobie szukać na mapce, ew. będzie wypełniać to pole za nas automatycznie, korzystając z naszej pozycji zczytanej z GPS'a
w urządzeniu mobilnym :).
