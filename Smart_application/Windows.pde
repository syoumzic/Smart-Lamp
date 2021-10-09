class AlarmClock extends Window {
  Bar[] on, off;

  Picker hour, minute;
  Button button;
  Scroll scroll;

  AlarmClock() {
    hour = new Picker(0, 24, width*0.3, height*0.3); //сноска для выбора часов
    minute = new Picker(0, 60, width*0.7, height*0.3);   //сноска для выбора минут
    scroll = new Scroll("Период пробуждения", 5, 20, "минут", width*.5, height*.6);
    button = new Button("выкл", "вкл", width*0.5, height*0.8);
    
    on = new Bar[]{hour, minute, scroll, button};
    off = new Bar[]{button};
  }
  
  void loadSettings(){
    for(Bar b: on)
      b.loadSettings();
    
    bars = (button.active)? on : off;
  }
  
  void draw() {
    textFont(big);
    fill(#555555);
    text(":", width/2, height*0.29);  //разделитель сносок часов и минут

    if (bars == on)
      super.draw();                      //отрисовываем все элементы окна

    else {
      super.draw();

      for (Bar b : on)
        b.draw();

      fill(125, 150);
      rect(0, 0, width, height);
    }
  }

  void exact(Button b) {
    if (b.active) {
      bars = on;
      write(new byte[]{ALARM_CLOCK_ENABLED, //отправка разници между временем пробуждения и текущим временем
              (byte)(hour.value - hour()), 
              (byte)(minute.value - minute()),
              (byte)(-second()),            //для пробужденяи точно в h, m, 0
              (byte)hour.value,
              (byte)minute.value,
              (byte)scroll.value()
            });
    }
    else {
      bars = off;
      write(new byte[]{ALARM_CLOCK_DISABLED});
    }
  }
  void exact(Picker p) {
    write(new byte[]{ALARM_CLOCK_SET_TIME, 
            (byte)(hour.value - hour()), 
            (byte)(minute.value - minute()),
            (byte)(-second()),
            (byte)hour.value,
            (byte)minute.value,
          });
  }
  void exact(Scroll s) {
    write(new byte[]{ALARM_CLOCK_SET_DURATION, 
            (byte)s.value()
          });
  }
}
//--------------------------------------------------------------------------------
class TimerWindow extends Window {
  Timer timer;
  Button button;
  Bar[] on, off;
  
  TimerWindow() {
    Picker hour   = new Picker(0, 24, width*0.15, height*0.35);  //часы: шрифт, от, до, позиция X, позиция Y
    Picker minute = new Picker(0, 60, width*0.5, height*0.35);  //минуты: шрифт, от, до, позиция X, позиция Y
    Picker second = new Picker(0, 60, width*0.85, height*0.35);  //секунды: шрифт, от, до, позиция X, позиция Y

    button = new Button("||", "▶", width*0.5, height*0.8);   //содержание, диаметр, позиция X, позиция Y 
    timer = new Timer(hour, minute, second, width*0.5, height*0.35);  //уже объявлен

    off = new Bar[]{hour, minute, second, button};
    on = new Bar[]{timer, button};
  }
  
  void loadSettings(){
    for(Bar b: off)
      b.loadSettings();
    
    if(button.active){
      bars = on;
      timer.init(); 
    }
    else
      bars = off;
  }
  
  void draw() {
    super.draw();

    if (bars == off) {
      fill(#555555);
      text(":", width*0.325, height*0.35-20);  //разделитель сносок часов и минут
      text(":", width*0.675, height*0.35-20);  //разделитель сносок минут и секунд
    }
  }

  void exact(Button b) {
    if (b.active) {
      bars = on;
      write(new byte[]{TIMER_ENABLED,
                   (byte)timer.hour.value,
                   (byte)timer.minute.value,
                   (byte)timer.second.value
                  });
                  
      timer.init();
    } 
    else{ 
      bars = off;
      write(new byte[]{TIMER_DISABLED});
    }
  }
  
  void exact(Picker p){
    write(new byte[]{TIMER_SET_TIME,
             (byte)(timer.hour.value), 
             (byte)(timer.minute.value),
             (byte)(timer.second.value)
           });
  }
}
//--------------------------------------------------------------------------------
class Metronome extends Window {
  Picker picker;
  Button button;
  Metronome() {
    picker = new Picker(10, 120, width*0.25, height*0.4); 
    button = new Button("||", "▶", width*0.5, height*0.8);
    
    bars = new Bar[]{picker, button};
  }
  
  void loadSettings(){
    for(Bar b: bars)
      b.loadSettings();
  }
  
  void exact(Button b){
    if(b.active){
      write(new byte[]{METRONOME_ENABLED,
                (byte)picker.value
              }); 
    }
    else
      write(new byte[]{METRONOME_DISABLED});
  }
  
  void exact(Picker p){
      write(new byte[]{METRONOME_SET_DURATION,
                (byte)picker.value
              });
  }
  
  boolean touched(){
    boolean touch = super.touched();
    if(update == picker && button.active){
      update = null;
      return false; 
    }
    return touch;
  }
  
  void draw() {
    super.draw();

    fill(#AAAAAA);
    text("ударов в\n минуту", width*0.7, height*0.4);    // "\n" разделитель строки
  }
}
//--------------------------------------------------------------------------------
class LightPicker extends Window {
  ColorWheel wheel;

  LightPicker() {
    Scroll scroll = new Scroll("яркость: ", 0, 255, " / 255", width*0.5, height*0.6);
    wheel =  new ColorWheel(scroll, width*0.5, height*0.3);//scroll для самостоятельное установки прозрачности

    bars = new Bar[]{wheel, scroll};
  }
  
  void loadSettings(){
    wheel.loadSettings(); 
  }
  
  void exact(Scroll s) {
    wheel.updateColor();
  }
  void exact(ColorWheel w) {
    write(new byte[]{LIGHT_SET_COLOR, 
            (byte)red(wheel.col), 
            (byte)green(wheel.col), 
            (byte)blue(wheel.col)
          });
  }
}
//------------------------------------------------------------------
class Error extends Window {
  void update() { 
    connect();
  }
  void draw() {
    fill(#000000);
    textFont(small);
    text("Ошибка подключения\n" + 
         "\nУбедитесь, что:\n" +
         "> лампа работает исправно\n" +
         "> вы подключены к лампе\n\n" + 
         "имя сети: lamp\n" + 
         "пароль сети: 123456789", width/2, height/4);
  }
  boolean touched() {
    return false;
  }
}
