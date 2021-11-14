#include <ESP8266WiFi.h>
#include <Adafruit_NeoPixel.h>

#define ssid "name"      //вставить сюда имя роутера
#define password "pass"  //вставить сюда пароль роутера

#define STRIP_LENGTH 40       //количество пикселей на лента
#define PIN D7                //шина передачи данных между лентой

/* данные констваты не менять! */

#define SETTINGS 1
#define ALARM_CLOCK_ENABLED 2
#define ALARM_CLOCK_DISABLED 3
#define ALARM_CLOCK_SET_TIME 4
#define ALARM_CLOCK_SET_DURATION 5
#define TIMER_ENABLED 6
#define TIMER_DISABLED 7
#define TIMER_SET_TIME 8
#define METRONOME_ENABLED 9
#define METRONOME_DISABLED 10
#define METRONOME_SET_DURATION 11
#define LIGHT_SET_COLOR 12
#define REALIZED 13
#define SKIP_ALARM_CLOCK 14

#define DAY 86400000
#define HOUR 3600000
#define MINUTE 60000
#define SECOND 1000

#define WHITE 65793
/*************************/

Adafruit_NeoPixel strip(STRIP_LENGTH, PIN, NEO_GRB + NEO_KHZ800); //количество светидиодов, пин к которому припаяна лампа, цветопередача и частота обновления ленты
WiFiServer server(10);
WiFiClient client;

int limitMax(int n, int max);
int limitMin(int n, int max);
int readTime();

struct Timer{
  long long mark;
  bool enabled = false;

  bool active(){
    return enabled && mark-millis() <= 0;
  }

  void setTime(){
    mark = millis() + readTime();
  }

  uint8_t getHours(){
    return uint8_t(limitMin(mark - millis(), 0) / HOUR);
  }
  uint8_t getMinutes(){
    return uint8_t(limitMin(mark - millis(), 0) % HOUR / MINUTE);
  }
  uint8_t getSeconds(){
    return uint8_t(limitMin(mark - millis(), 0) % MINUTE / SECOND);
  }

  void show(){
    strip.clear();      //очищаем ленту
    strip.show();       //показываем изменения в ленте
    enabled = false;    //выключаем таймер
  }
  
} timer;

struct Metronom {
  int duration = 1500;
  bool enabled = false;

  void setDuration(){
    byte c = client.read();
    duration = (int)(MINUTE / c);
  }
  
  void show() {
    uint8_t x = 255 * millis() / duration;                //преобразуем возрастающий график в синусоиду с заданным периодом
    strip.fill(strip.sine8(x) * WHITE, 0, STRIP_LENGTH);  //окрашиваем ленту в оттенок белого
    strip.show();                                         //показываем результат
  }

  bool active(){
    return enabled;
  }
} metronome;

struct AlarmClock {
  long long mark;
  uint8_t hour = 0;
  uint8_t minute = 0;
  int duration = 600000;
  bool enabled;

  bool active() {
    return enabled && mark - millis() <= 0;
  }

  void setTime(){
    int d = readTime(); //3 байта
    
    if (d >= 0)
      mark = millis() + limitMin(d, 5000);
    else
      mark = millis() + d + DAY;
      
    hour = client.read();   //в часах
    minute = client.read(); //в минутах
  }

  void setDuration(){
    duration = (int8_t)client.read() * MINUTE;
  }

  void show() {
    int d = millis() - mark;                                          //время, прошедшее с включения будильника
    uint8_t brightness = (uint8_t)limitMax(255 * d / duration, 255);  //переводим данное время из диапозона [0;duration] в [0;255]
    strip.fill(brightness * WHITE, 0, STRIP_LENGTH);                  //окрашиваем ленту в белый (STRIP_LENGTH - длинна ленты)
    strip.show();                                                     //выводим цвет на ленту

    if(d > DAY)                                                       //если уже прошёл целый день с включения будильника, то обновлем его
      mark += DAY;
  }

} alarmClock;

uint32_t color = 0x808080;  //начальный цвет

void setup() {
  Serial.begin(115200);
  
  strip.begin();
  strip.fill(color, 0, STRIP_LENGTH);
  strip.show();   
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  Serial.print("\nПодключаюсь к роутеру");
  while (WiFi.status() != WL_CONNECTED){
    Serial.print(".");
    delay(125);
  }
  
  Serial.println("\nГотово!\nlampIp = \"" + WiFi.localIP().toString() + "\"");
  server.begin();
}

void exact(int command) {
  switch (command) {  //проверка команды
    case LIGHT_SET_COLOR: {
      color = strip.Color(client.read(), client.read(), client.read()); //установка бызового цвета
      strip.fill(color, 0, STRIP_LENGTH);                               //окраска в него
      strip.show();                                                     //показ окраски

      timer.enabled = false;                                            //выключение таймера
      metronome.enabled = false;                                        //выключение метронома
    }
    break;

    case ALARM_CLOCK_ENABLED: {
      alarmClock.setTime();
      alarmClock.setDuration();
      alarmClock.enabled = true;      //включение
    }
    break;

    case ALARM_CLOCK_DISABLED: {
      alarmClock.enabled = false;    //выключение
    }
    break;

    case ALARM_CLOCK_SET_TIME: {
      alarmClock.setTime();          //установка вемени
    }
    break;

    case ALARM_CLOCK_SET_DURATION: {
      alarmClock.setDuration();     //установка продолжительности действия будильника
    }
    break;

    case SKIP_ALARM_CLOCK:{         //перенос будильника (его не полное выключение)
      if(alarmClock.active())
        alarmClock.mark += DAY;
    }
    break;

    case TIMER_ENABLED:{  //3 байта
      timer.setTime();  //3 байта
      
      strip.clear();
      strip.show();
      delay(250);
      
      strip.fill(color, 0, STRIP_LENGTH);
      strip.show();

      timer.enabled = true;
      metronome.enabled = false;
    }
    break;

    case TIMER_DISABLED:{
      timer.enabled = false;
    }
    break;
    
    case TIMER_SET_TIME:{ //3 байта
      timer.setTime();  //3 байта
    }
    break;

    case METRONOME_ENABLED:{  //1 байт
      metronome.setDuration();  //1 байт
      
      metronome.enabled = true;
      timer.enabled = false;
    }
    break;

    case METRONOME_DISABLED:{
      strip.fill(color, 0, STRIP_LENGTH);
      strip.show();
      
      metronome.enabled = false;
    }
    break;
    
    case METRONOME_SET_DURATION:{ //1 байт
      metronome.setDuration();  //1 байт
    }
    break;
    
    case SETTINGS: {
      client.write(alarmClock.hour);                    //отправка часы будильника
      client.write(alarmClock.minute);                  //отправка минуты будильника 
      client.write(alarmClock.duration / MINUTE);       //отправка время пробуждения 
      client.write(alarmClock.enabled);                 //отправка включенности лампы
                                
      client.write(timer.getHours());                   //отправка текущих часов таймера
      client.write(timer.getMinutes());                 //отправка такущих минут таймера
      client.write(timer.getSeconds());                 //отправка текущех секунд таймера
      client.write(timer.enabled? 1 : 0);               //отправка  включенности таймера

      client.write(MINUTE / metronome.duration);        //частота метронома
      client.write(metronome.enabled? 1 : 0);           //включение метронома

      client.write(color >> 16);                        //первые 8 байт цвета (красный цвет)
      client.write(color >> 8);                         //последющие 8 байт цвета (зелёный цвет)
      client.write(color);                              //последние 8 байт цвета (синий цвет)
    }
    break;
  }
}

  
int limitMin(int n, int min){
  return(n < min)? min : n;
}

int limitMax(int n, int max){
  return (n > max)? max : n;
}

int readTime(){
  return (int8_t)client.read() * HOUR + (int8_t)client.read() * MINUTE + (int8_t)client.read() * SECOND;
}
void loop() {
  if (!client.connected()) {                                  //пока нет подключения
    client = server.available();                              //подключаем
  }
  else if (client.available() > 0) {                          //если есть данные
    client.write(REALIZED);
    exact(client.read());                                     //выполняем полученную команду
   }
  
  if (alarmClock.active())
    alarmClock.show();
    
  else if(timer.active())
    timer.show();
    
  else if(metronome.active())
    metronome.show();
}
