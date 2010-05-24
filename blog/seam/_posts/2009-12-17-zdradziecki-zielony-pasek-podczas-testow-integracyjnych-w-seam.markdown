---
layout: post
title: Zdradziecki zielony pasek podczas testów integracyjnych w Seam
description: O tym dlaczego nie można ufać zielonemu paskowi w testach integracyjnych w Seam framework. Dlaczego przechodzące testy niekoniecznie oznaczają sukces.
keywords: Seam framework testy integracyjne ExceptionFilter SeamPhaseListener
---
Uruchamiając testy integracyjne w Seam framework nie możemy ufać zielonemu paskowi w naszym wypieszczonym Eclipse z pluginem TestNG. Niestety, zielony nie zawsze oznacza, że wszystko poszło zgodnie z planem. Niestety część problemów jest przez Seam (chcąc nie chcąc) ukrywana i daj Boże jeżeli niektóre z tych sytuacji pozostawiają jakiś ślad w konsoli. Czasami może być tak, że jakaś faza naszego symulowanego cyklu JSF po prostu się nie odpaliła i cała logika w ogóle nie została przetestowana. Innym razem przeglądając logi konsoli możemy natknąć się na:

<pre>
ERROR [org.jboss.seam.exception.Exceptions] handled and logged exception
org.jboss.seam.security.AuthorizationException: Authorization check failed for expression [#{s:hasRole('Provider')}]
  at org.jboss.seam.security.Identity.checkRestriction(Identity.java:222)
  at org.jboss.seam.navigation.Page.checkPermission(Page.java:263)
  at org.jboss.seam.navigation.Page.preRender(Page.java:283)
  at org.jboss.seam.navigation.Pages.preRender(Pages.java:350)
  ...
</pre>

Nasza akcja nie powiodła się z powodu braku autoryzacji użytkownika (ze względu na nieposiadaną rolę). Heh, ale test jest zielony i gdybyśmy nie spojrzeli w konsolę prawdopodobnie żylibyśmy z błogą świadomością, że wszystko jest ok. Powyższy fragment jest de facto logiem a nie stack tracem po nieprzechwyconym wyjątkiem, ponieważ wyjątek nie wyszedł poza Seam-a. Stąd też trudne jest w tej sytuacji przetestowanie próby nieautoryzowanego wejścia ponieważ nie możemy po prostu polegać na rzuconym wyjątku (gdyż nie wyjdzie on poza kontener).

Wszystkiemu winna jest klasa `ExceptionFilter` która w metodzie `endWebRequestAfterException` postanowiła obsłużyć nasz wyjątek. W metodzie tej mamy:

{% highlight java %}
//Now do the exception handling
try
{
    rollbackTransactionIfNecessary();
    Exceptions.instance().handle(e);
}
{% endhighlight %}

Podążając za delegację do klasy `Exceptions` natykamy się na:

{% highlight java %}
switch (eh.getLogLevel())
{
case fatal: 
    log.fatal("handled and logged exception", e);
    break;
case error:
    log.error("handled and logged exception", e);
    break;
case warn:
    log.warn("handled and logged exception", e);
    break;
case info:
    log.info("handled and logged exception", e);
    break;
case debug: 
    log.debug("handled and logged exception", e);
    break;
case trace:
    log.trace("handled and logged exception", e);
}
{% endhighlight %}

i właściwie to tyle, po tym jeszcze tylko zgłaszane są zdarzenia:

{% highlight java %}
Events.instance().raiseEvent("org.jboss.seam.exceptionHandled." + cause.getClass().getName(), cause);
Events.instance().raiseEvent("org.jboss.seam.exceptionHandled", cause);
{% endhighlight %}

No i pięknie. Mimo iż system nie pozwolił na wykonanie akcji, ba nastąpiła próba nieautoryzowanego dostępu do zasobu, to test wykona się poprawnie, ponieważ wyjątek nie opuści naszego kontenera. Nie wiem dokładnie po co Seam zjada te wyjątki, ale pewnie dlatego, że posiada funkcjonalność pozwalającą dokonywać przekierowań w zależności od zgłoszonego wyjątku (co notabene nie działa w przypadku akcji odpalanych w deskryptorach page.xml, ale to temat na inną bajkę ;)).

Co jeszcze ciekawsze, gdybyśmy napisali komponent obserwujący zdarzenie "org.jboss.seam.exceptionHandled" w którym rzucilibyśmy zgłoszony wyjątek nie rozwiązałoby to problemu:

<pre>
ERROR [org.jboss.seam.exception.Exceptions] handled and logged exception
org.jboss.seam.security.AuthorizationException: Authorization check failed for expression [#{s:hasRole('Provider')}]
  at org.jboss.seam.security.Identity.checkRestriction(Identity.java:222)
  at org.jboss.seam.navigation.Page.checkPermission(Page.java:263)
  at org.jboss.seam.navigation.Page.preRender(Page.java:283)
  at org.jboss.seam.navigation.Pages.preRender(Pages.java:350)
  at org.jboss.seam.jsf.SeamPhaseListener.preRenderPage(SeamPhaseListener.java:561)
  ...
ERROR [org.jboss.seam.jsf.SeamPhaseListener] swallowing exception
org.jboss.seam.security.AuthorizationException: Authorization check failed for expression [#{s:hasRole('Provider')}]
  at org.jboss.seam.security.Identity.checkRestriction(Identity.java:222)
  at org.jboss.seam.navigation.Page.checkPermission(Page.java:263)
  at org.jboss.seam.navigation.Page.preRender(Page.java:283)
  at org.jboss.seam.navigation.Pages.preRender(Pages.java:350)
  at org.jboss.seam.jsf.SeamPhaseListener.preRenderPage(SeamPhaseListener.java:561)
  ...
</pre>

Tym razem wyjątek połknął nam `SeamPhaseListener`.

Nie wiem jeszcze czy Seam ma jakieś rozwiązanie na to (oczywiście w dokumentacji i książkach o tym frameworku fakt ten skrzętnie przemilczano :)). Na razie polecam przyglądnięcie się logom z własnych testów i upewnienie się, że wszystkie przechodzą, gdyż działają, a nie ponieważ się nie odpaliły.