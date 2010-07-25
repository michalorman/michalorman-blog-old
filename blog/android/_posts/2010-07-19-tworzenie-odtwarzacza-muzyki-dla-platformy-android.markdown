---
layout: post
title: Tworzenie odtwarzacza muzyki dla platformy android
description: W jaki sposób można stworzyć prostą aplikacją odtwarzającą muzykę dla platformy Android.
keywords: MediaPlayer Android odtwarzacz muzyka
---

I po urlopie. Ostatni okres minął mi na szlifowaniu opalenizny i całkowitym odizolowaniu się od wszelkich
informatyczno-programistycznych tematów. Jako, że urlop mam już za sobą czas powrócić do pracy i blogowania.

W tym wpisie postanowiłem przedstawić w jaki sposób platforma Android pozwala nam wykorzystywać
pliki multimedialne, a w szczególności muzykę. Pokażę jak można stworzyć prostego odtwarzacza muzyki a także
jak dodać dźwięki (co przyda się zwłaszcza przy tworzeniu gier).

## Wspierane formaty

Jeżeli chodzi formaty dźwięku jakie wspiera platofrma Android to pełną ich listę znajdziemy (tutaj)[http://developer.android.com/guide/appendix/media-formats.html#core].
Z listy tej warto wymienić następujące formaty:

  * WAV (WAVE, PCM),
  * MP3 (MPEG-3),
  * Ogg Vorbis

Te formaty są raczej wspierane przez wszystkie użądzenia ponieważ - zgodnie z dokumentacją - są wbudowane w
platformę Android. Konkretne urządzenia mogą oferować dodatkowe formaty nie wspierane przez inne, stąd
jeżeli nie chcemy ograniczać się do konkretnego urządzenia powinniśmy korzystać z powyższych formatów.

## Odgrywanie dźwięków

Zacznijmy od odgrywania dźwięków. Po pierwsze potrzebujemy... dźwięków. Odpowiednie pliki powinny
znaleźć się w katalogu ``res/raw``. Pliki umieszczone w katalogu ``res`` będą posiadały wygenerowane
identyfikatory do których odwołujemy się z pomocą klasy ``R``. W katalgu``raw`` powinny znajdować się
wszelkie pliki, które nie powinny być parsowane przez platformę.

W moim przypadku struktura katalogów wygląda następująco:

  + res
   \
    + raw
       \
        - sword1.wav
        - sword2.wav
        - sword3.wav
        - sword4.wav

Teraz zaimplementujmy prostą aplikację odtwarzającą losowo któryś z dźwięków w momencie kliknięcia
przez użytkownika w ekran.

Layout takiej aplikacji praktycznie nie istnieje zatem go pominę i przejdę do aktywności.

{% highlight java %}
public class Sound extends Activity {

    private static final int SOUNDS[] = { R.raw.sword1, R.raw.sword2, R.raw.sword3, R.raw.sword4 };

    private Random random = new Random();

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        return super.onTouchEvent(event);
    }

    private int nextSoundId() {
        return SOUNDS[random.nextInt(SOUNDS.length)];
    }
}
{% endhighlight %}

Teraz, aby dodać odtwarzanie dźwięku musimy utowrzyć obiekt klasy ``android.media.MediaPlayer`` podając
identyfikator dźwięku jaki chcemy odtworzyć. 