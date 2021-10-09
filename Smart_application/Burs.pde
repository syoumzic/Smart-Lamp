class Button extends Bar {
  float x, y, size;
  String enable, disable;
  boolean active;

  Button(String disable, String enable, float x, float y) {
    this.x = x;
    this.y = y;
    
    this.enable = enable;
    this.disable = disable;
    this.size = width/5;
  }
  
  void loadSettings(){
    this.active = read() != 0;
  }
  
  void draw() {
    color col = (active)? #0FC1FF : #AAAAAA;
    
    stroke(col);
    noFill();
    ellipse(x, y, size, size);

    textFont(medium);
    fill(col);
    text(active? enable : disable, x, y-5);
  }

  void init() {
    active = !active;
    update.exact(this);   //выполнение команды (разная в разных классах окна)
  }

  boolean touched() {
    return dist(x, y, mouseX, mouseY) < size/2;
  }
}
//--------------------------------------------------------------------------------
class Scroll extends Bar {
  String name, p;
  int begin, end;
  int half_height = height / 30;
  float x, y, cursor_x;

  Scroll(String name, int begin, int end, String p, float x, float y) {
    this.x = x;
    this.y = y;

    this.name = name;
    this.p = p;

    this.begin = begin;
    this.end = end;
  }
  
  void loadSettings(){
    set(read(), begin, end);
  }

  void update() {
    cursor_x = constrain(mouseX, width*0.1, width*0.9);
    update.exact(this);
  }

  void set(float value, float max, float min) {
    cursor_x = map(value, max, min, width*0.1, width*0.9);
  }

  void draw() {
    strokeWeight(half_height);

    stroke(#AAAAAA);
    line(cursor_x, y, width*0.9, y);

    stroke(#0FC1FF);
    line(width*.1, y, cursor_x, y); 

    textFont(small);
    fill(#AAAAAA);
    text(name + " " + int(value()) + " " + p, x, y+half_height*2);
    
    strokeWeight(1);
  }

  float value() {
    return map(cursor_x, width*0.1, width*0.9, begin, end);
  }

  boolean touched() {
    return mouseY > y-half_height && mouseY < y+half_height;
  }
}
//--------------------------------------------------------------------------------
class Picker extends Bar {
  int begin, end, mouse_y, last_value, value;
  float x, y;
  
  Picker(int begin, int end, float x, float y) {
    this.x = x;
    this.y = y;

    this.begin = begin;
    this.end = end;
  }
  
  void loadSettings(){
     this.value = read();
  }
  
  void init() {
    last_value = value;
    mouse_y = mouseY;  //запоминаем положение мышки
  }

  void draw() {
    textFont(big);
    fill(#555555);
    text(nf(value, 2), this.x, this.y); 

    fill(#AAAAAA);
    text(nf(value == begin? end-1 : value-1, 2), x, y - textAscent());
    text(nf((value - begin + 1) % (end - begin) + begin, 2), x, y + textAscent());
  }

  void update() {
    value = loop(last_value + (mouse_y - mouseY) / textAscent(), begin, end);
    update.exact(this);
  }

  boolean touched() {
    return mouseY > y-height/7 && mouseY < y+height/7 && mouseX > x-width/4 && mouseX < x+width/4;  //float ?
  }
}
//--------------------------------------------------------------------------------
class Timer extends Bar {
  Picker hour, minute, second;
  long mark;
  float x, y;

  Timer(Picker hour, Picker minute, Picker second, float x, float y) {
    this.x = x;
    this.y = y;
    
    this.hour = hour;
    this.minute = minute;
    this.second = second;
  }
  
  void loadSettings(){
    hour.loadSettings();
    minute.loadSettings();
    second.loadSettings();
    init();
  }
  
  void init(){
    mark =                            //заведённое время (в миллисикундах) зависит от:  
      System.currentTimeMillis() +    //времени старта будуильника (относительно 1 января 1970 года),
      hour.value * HOUR +          //часов
      minute.value * MINUTE +           //минут
      (second.value + 1) * SECOND; 
  }
  long limitMin(long n, int min){
    return(n < min)? min : n;
  }
  void draw() {
    long d = limitMin(mark - System.currentTimeMillis(), 0);
    int dHour =   int(d / HOUR);
    int dMinute = int(d % HOUR / MINUTE);
    int dSecond = int(d % MINUTE / SECOND);

    fill(#555555);
    textFont(big);
    text(nf(dHour, 2) + ":" + nf(dMinute, 2) + ":" + nf(dSecond, 2), x, y);
  }
}
//--------------------------------------------------------------------
class ColorWheel extends Bar {
  PImage wheel;
  float x, y, size;
  float cursor_size, cursor_x, cursor_y;
  int col = #7f7f7f;
  Scroll scroll;

  ColorWheel(Scroll scroll, float x, float y) {
    this.x = x;
    this.y = y;

    this.scroll = scroll;

    this.size = width * 0.7;
    this.cursor_size = width / 10;

    wheel = loadImage("wheel.png");
    wheel.resize((int)size, (int)size);
  }
  
  void loadSettings(){
    col = color(read(), read(), read());
    float radius = size * saturation(col) / 510;
    float angle = TWO_PI * hue(col) / 255;
     
    cursor_x = cos(angle) * radius;
    cursor_y = sin(angle) * radius;
     
    scroll.set(brightness(col), 0, 255);
  }

  void update() {
    if (dist(mouseX, mouseY, x, y) >= size/2) {                          //если пользователь завёл куазатель за пределы круга
      float angle = angle(mouseX, mouseY, x, y);                      //рассчитываем угол в радиантах через atan2
      cursor_x = cos(angle) * (size/2-1);                                //рассчёт координат на окружности
      cursor_y = sin(angle) * (size/2-1);                                //относительно центра круга
    } else {
      cursor_x = mouseX - (int)x;
      cursor_y = mouseY - (int)y;
    }

    updateColor();
  }

  void updateColor() {
    col = wheel.get(int(cursor_x + size/2), int(cursor_y + size/2));
    col = lerpColor(#000000, col, scroll.value() / 255f);
    update.exact(this);
  }

  void draw() {
    image(wheel, x, y);

    fill(#000000, 255 - scroll.value());                              //затемнение (чёрный цвет с меняющеюся прозрачностью)
    noStroke();
    ellipse(x, y, size, size);

    stroke(#AAAAAA);
    fill(col);                 //берём цвет, на который указывает курсор
    ellipse(x + cursor_x, y + cursor_y, cursor_size, cursor_size);
  }

  boolean touched() {
    return dist(mouseX, mouseY, x, y) < size/2;
  }
}
//---------------------------------------------------------------------
