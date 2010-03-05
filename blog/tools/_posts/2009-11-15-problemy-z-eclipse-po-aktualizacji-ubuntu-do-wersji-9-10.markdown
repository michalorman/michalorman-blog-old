---
layout: post
title: Problemy z Eclipse po aktualizacji Ubuntu do wersji 9.10
description: Problem z Eclipse po aktualizacji Ubuntu do wersji 9.10. Niedziałające przyciski w aplikacji Eclipse.
keywords: ubuntu 9.10 eclipse ide
---
Użytkownicy <a href="http://www.ubuntu.com/">Ubuntu</a> i <a href="http://www.eclipse.org/">Eclipse</a> mieli niemiłą niespodziankę po aktualizacji systemu Ubuntu do wersji 9.10 (Karmic Koala). Otóż okazało się, że niektóre przyciski przestały wykonywać swoje akcje. Klikanie w niektóre z nich po prostu nie robiło niczego. Można to było ominąć zaznaczając myszką odpowiedni przycisk i wciśnięcie klawisza ENTER na klawiaturze, albo użycie odpowiedniego skrótu klawiszowego. Wygląda zatem, że Eclipse miał problemy z przechwyceniem (albo poprawnym zinterpretowaniem) zdarzenia kliknięcia myszką na przycisku. Ciekawe tylko, czemu niektóre przyciski działały a inne nie :).

W każdym razie problem ten występował w Eclipsie zarówno w wersji 3.4 jak i 3.5. Dodatkowo w tej drugiej po wejściu w panel instalowania nowych dodatków po wybraniu jakiegokolwiek źródła lista z dostępnym oprogramowaniem się nie renderowała (co ciekawe przesuwając w tym obszarze myszką można było natrafić na przyciski rozwijające drzewo i kliknięcie go czasem powodowało, że drzewo się magicznie pojawiało). Resetowałem nawet ustawienia Gnome w Ubuntu, jednak niczego to nie zmieniało. Trzeba jeszcze zaznaczyć, że problem z przyciskami nie występował w Eclipsie instalowanym prosto z repozytorium Ubuntu (tam jest dostępna wersja 3.5.1 Classic a ja chciałem mieć JEE), za to ten drugi (z drzewem) o ile dobrze pamiętam już tak.

W każdym razie oba problemy można rozwiązać w prosty sposób. Jeżeli uruchamiamy Eclipse przy użyciu skryptu startowego należy dodać odpowiedni parametr (w przypadku braku takiego skryptu należy go stworzyć):

{% highlight bash %}
#!/bin/sh
export GDK_NATIVE_WINDOWS=1
$ECLIPSE_HOME/eclipse
{% endhighlight %}

Gdzie zmienna `ECLIPSE_HOME` to wasza ścieżka do katalogu domowego Eclipse. Skrypt ten w magiczny sposób rozwiązał wszystkie moje problemy. Trzeba tylko pamiętać, że prawidłowo Eclipse będzie działał tylko w momencie, kiedy zostanie uruchomiony przez ten skrypt! Na przykład podczas restartu aplikacji (np. po instalacji nowego pluginu) tak się nie dzieje, więc trzeba go ręcznie zrestartować.

Podobno błąd jest naprawiony w Eclipse 3.6, ale nie sprawdzałem.

Oryginalnie rozwiązanie znajduje się <a href="http://www.norio.be/blog/2009/10/problems-eclipse-buttons-ubuntu-910">tutaj</a>.