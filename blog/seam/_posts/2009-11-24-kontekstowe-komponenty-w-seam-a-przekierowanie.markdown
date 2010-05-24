---
layout: post
title: Kontekstowe komponenty w Seam a przekierowanie
description: Problem z komponentami w kontekście konwersacji po przekierowaniu w Seam Framework. Dlaczego komponenty w konwersacji nie przeżywają przekierowania.
keywords: seam framework contextual comnponents conversation redirect
---
Ci, którzy znają framework <a href="http://www.seamframework.org/">Seam</a> zapewne wiedzą, że główną cechą komponentów umieszczonych w kontekście konwersacji jest to, że przeżywają one przekierowanie. Tak więc renderując widok po przekierowaniu mamy dostęp do danych umieszczonych w tych komponentach przed przekierowaniem. Otóż okazuje się, że nie jest tak zawsze.

Aby zrozumieć problem najpierw trzeba sobie uświadomić, że Seam rozróżnia dwa rodzaje akcji:

1. Akcje strony (zdefiniowane w pliku pages.xml albo odpowiadającym stronie).
1. Normalne akcje JSF-owe.

Akcje strony zostały wprowadzone po to, aby można było podjąć jakiekolwiek działanie przed wyrenderowaniem strony i zatwierdzeniem formularza (np. jakieś sprawdzanie związane z bezpieczeństwem). Te drugie akcje to zwykłe akcje JSF-owe, które odpowiadają za obsługę zatwierdzenia formularza. Można zatem przyjąć, że te pierwsze to są akcje GET-owe, a te drugie POST-owe. Ponieważ JSF nie wspiera akcji GET-owych Seam musiał uciec się do małego fortelu.

W standardowym modelu JSF akcje odpalane są w 5-tej fazie tzw. Invoke Application. Jednak w przypadku akcji GET-owych mamy do czynienia ze skróconym obiegiem JSF w którym występują tylko fazy 1 (Restore View) oraz 6 (Render Response). Dzieje się tak dlatego, że kolejne fazy (apply request values, process validations, itd.) są wykonywane na drzewie zbudowanym (przywróconym) w fazie pierwszej, ponieważ w GET-owym żądaniu nie mamy jeszcze drzewa JSF po prostu przenosi nas do fazy 6-tej w której owe drzewo jest renderowane. Zatem Seam aby móc odpalić akcję w skróconym przebiegu podpina swojego PhaseListener'a który wpina się w poszczególne fazy JSF i uruchamia naszą akcję w trochę niestandardowym momencie, a dokładnie tuż przed wywołaniem 6-tej fazy (tzw. before render response). W tym momencie nasza logika wrzuca dane do komponentów znajdujących się w konwersacji (długiej lub krótkiej), zwraca outcome na który ustawione jest przekierowanie.

Ten sam PhaseListener (prawdopodobnie ten sam, bo doświadczalnie nie sprawdzałem) ma jeszcze jedno zadanie. Mianowicie usuwa on i tworzy obiekty w kontekście konwersacji. Owa operacje dzieje się tuż po 6-tej fazie (tzw. after render response). Zatem jeżeli mieliśmy akcję GET-ową i wrzucaliśmy dane do komponentów w kontekście konwersacji to te komponenty za chwilę zostaną usunięte a w ich miejsce zostaną stworzone nowe (o ile nie mieliśmy długiej konwersacji). Zatem nasze komponenty konwersacyjne **nie przeżyją** przekierowania! Przekierowanie następuje po pełnej fazie (po after) a nie w środku fazy!

Aby to lepiej zrozumieć zobaczmy co dzieje się w przypadku akcji POST-owych i GET-owych. W przypadku żądania POST-owego mamy kolejno uruchamiane fazy:

1. Faza 1: przywrócenie widoku (drzewa komponentów JSF)
1. Faza 2: wprowadzenie wartości z formularza do komponentów, konwersja
1. Faza 3: uruchomienie walidacji
1. Faza 4: aktualizacja modelu, wprowadzenie wartości z komponentów do ziaren (managed-beans)
1. Faza 5: ruchomienie aplikacji:
  1. Faza przed (before)
  1. Faza główna - tutaj uruchamiana jest nasza akcja
  1. **Faza po - tutaj następuje przekierowanie**
1. Faza 1: przywrócenie nowego widoku (po przekierowaniu)
1. Faza 6: renderowanie nowego widoku (drzewa komponentów JSF)
  1. Faza przed
  1. **Faza po - tutaj następuje usunięcie i stworzenie nowych komponentów w kontekście konwersacji**

Natomiast tak wyglądać będzie obsługa żądania i akcja GET-owa:

1. Faza 1: przywrócenie widoku (drzewa komponentów JSF)
1. Faza 6: renderowanie widoku (drzewa komponentów JSF)
  1. Faza przed - tutaj uruchamiana jest nasza akcja GET-owa
  1. **Faza po - tutaj następuje usunięcie i stworzenie nowych komponentów w kontekście konwersacji oraz przekierowanie**
1. Faza 1: przywrócenie nowego widoku (po przekierowaniu)
1. Faza 6: renderowanie nowego widoku (drzewa komponentów JSF)
  1. Faza przed
  1. **Faza po - tutaj następuje usunięcie i stworzenie nowych komponentów w kontekście konwersacji**

Zatem w przypadku akcji GET-owej nie ma mowy o tym aby komponenty z kontekstu konwersacji były nieruszone po przekierowaniu.

Nie wiem do końca co o tym myśleć, jednak wygląda to na błąd w frameworku Seam. Powinien on być świadomy tego, jaką akcję obsługuje i że komponenty powinny zostać nieruszone. Nie wiem tylko jakie jeszcze operacje są wykonywane w fazie after render response. Na wszelki wypadek zadałem pytanie na <a href="http://www.seamframework.org/Community/CreatingNewConversationAfterTheRedirectFromPageAction">forum</a> Seam-a, zobaczymy co mi tam odpowiedzą (albo mnie zignorują :P). Być może pofatyguję się i wystawię im zadanko w JIRZE :).

Powyższe dywagacje to wyniki moich obserwacji. Nie jestem deweloperem Seam-a więc głowy sobie nie dam uciąć, że to wszystko dokładnie tak przebiega. Jednakże z analizy działania aplikacji, komponentów umieszczanych w kontekście konwersacji i uruchamianych faz JSF wynika, że tak właśnie wygląda przebieg obsługi konkretnych żądań gdy następuje przekierowanie.