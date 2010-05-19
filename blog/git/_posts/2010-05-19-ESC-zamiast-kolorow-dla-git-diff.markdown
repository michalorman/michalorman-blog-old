---
layout: post
title: ESC[ zamiast kolorów dla git diff
description: Jak poradzić sobie z problemem wyświetlania znaków ESC zamiast kolorów w komendach git diff, git log w systemi OpenSUSE
keywords: git diff log ESC ESC[ kolor opensuse
navbar_pos: 1
---
Od jakiegoś czasu miałem problem z [Git-em](http://git-scm.com/). Kiedy wykonywałem komendę
``git diff`` zamiast łądnie pokolorowanego wyniku dostawałem:

    ESC[1mdiff --git a/_includes/categories.html b/_includes/categories.htmlESC[m
    ESC[1mindex aba605a..825683b 100644ESC[m
    ESC[1m--- a/_includes/categories.htmlESC[m
    ESC[1m+++ b/_includes/categories.htmlESC[m
    ESC[36m@@ -3,6 +3,7 @@ESC[m
      <li><a href="/blog/architektura/" title="Zobacz wszystkie posty w kategorii architektura">architektura ({{ site.categories.architektura.size }})</a></li>ESC[m
      <li><a href="/blog/certyfikaty/" title="Zobacz wszystkie posty w kategorii certyfikaty">certyfikaty ({{ site.categories.certyfikaty.size }})</a></li>ESC[m
      <li><a href="/blog/general/" title="Zobacz wszystkie posty w kategorii general">general ({{ site.categories.general.size }})</a></li>ESC[m
    ESC[32m+ESC[mESC[32m  <li><a href="/blog/git/" title="Zobacz wszystkie posty w kategorii git">git ({{ site.categories.git.size }})</a></li>ESC[m
      <li><a href="/blog/javaee/" title="Zobacz wszystkie posty w kategorii javaee">javaee ({{ site.categories.javaee.size }})</a></li>ESC[m
      <li><a href="/blog/jboss/" title="Zobacz wszystkie posty w kategorii jboss">jboss ({{ site.categories.jboss.size }})</a></li>ESC[m
      <li><a href="/blog/oop/" title="Zobacz wszystkie posty w kategorii oop">oop ({{ site.categories.oop.size }})</a></li>ESC[m
    ESC[1mdiff --git a/sitemap.xml b/sitemap.xmlESC[m
    ESC[1mindex ed0c299..49779da 100644ESC[m
    ESC[1m--- a/sitemap.xmlESC[m
    ESC[1m+++ b/sitemap.xmlESC[m

Generalnie problem ten przez dłuższy czas ingorowałem, ale zaczął on mnie coraz bardziej irytować zwłaszcza, że
dotyczył także komendy ``git log``:

    ESC[33mcommit 68b002cba84c6cd27aace5e63e18310bbeb4034dESC[m
    Author: Michal Orman <michal.orman@gmail.com>
    Date:   Tue May 18 19:07:50 2010 +0200

        Fixed typos.

    ESC[33mcommit 51a93ec1298057dc66dbbdba80a75bdaf1110797ESC[m
    Author: Michal Orman <michal.orman@gmail.com>
    Date:   Tue May 18 11:30:56 2010 +0200

        Added post about activities and intents in android platform.

A z tej drugiej korzystam już dużo więcej (w przypadku tej pierwszej radziłem sobie graficznym narzędziem).

Co się okazało? Otóż Git przetwarzał wyniki działania tych komend przez komendę ``less`` a jej wyniki wyświetlane były na ekranie. Domyślne
działanie komendy ``less`` nie uwzględnia kolorowania (a właściwie nie wyświetla tzw. "raw" control characters). Jak zawsze w takich przypadkach należy
użyć odpowiedniego przełącznika. W tym przypadku są to przełączniki ``-r`` albo ``-R``. Oto wyciąg z manuala dla komendy ``less``:

    -r or --raw-control-chars
          Causes  "raw"  control characters to be displayed.  (...)

    -R or --RAW-CONTROL-CHARS
          Like -r, but only ANSI "color" escape sequences are output in "raw" form. (...) ANSI "color" escape sequences are sequences of the form:

                   ESC [ ... m

Wystarczy w naszym pliku ``.bashrc`` albo ``.profile`` ustawić odpowiedni przełącznik do zmiennej środowiskowej ``LESS``, która jest wykorzystywana
przez tę komendę:

{% highlight bash %}
export LESS="-erX"
{% endhighlight %}

Ja dodatkowo dodałem sobie przełączniki ``-e`` oraz ``-X``, ale nie są one konieczne do rozwiązania problemu. Przełącznik ``-e`` spowoduje wyjście
z komendy ``less`` po dodtarciu do końca wyświetlanego tekstu (inaczej trzeba wychodzić z pomocą przysiku q), natomiast ``-X`` spowoduje, że wyniki
nie będą wyświetlane w nowej sesji (ciężko to trochę wytłumaczyć dlatego lepiej samemu poeksperymentować z przełącznikami i przekonać się
na własne oczy o co chodzi).

Zamiast ``-r`` można oczywiście wykorzystać ``-R``, która działa jedynie w przypadku kolorów, jednakże w tym przypadku możemy w diff-ach otrzymywać
znaki ``^M`` na końcach wierszy, przełącznik ``-r`` likwiduje te artefakty. Jednakże w przypadku ``-r`` możemy doświadczyć dziwnych problemów
z komendą ``less``, dlatego jeżeli namiętnie korzystamy z tej komendy warto sprawdzić, w razie problemów, czy ten przełacznik nie psuje nam
sprawy.

Jeżeli powyższe instrukcje nie zadziałały może się okazać, że Git nie używa komendy ``less`` a innej (np. ``more``). W takiej sytuacji
musimy ustawić jeszcze zmienną ``GIT_PAGER``:

{% highlight bash %}
export LESS="-erX"
export GIT_PAGER=less
{% endhighlight %}

Od tej chwili wszystko działa jak należy.