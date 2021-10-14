import java.net.InetSocketAddress;
import java.net.Socket;

final byte SETTINGS = 1;
final byte ALARM_CLOCK_ENABLED = 2;
final byte ALARM_CLOCK_DISABLED = 3;
final byte ALARM_CLOCK_SET_TIME = 4;
final byte ALARM_CLOCK_SET_DURATION = 5;
final byte TIMER_ENABLED = 6;
final byte TIMER_DISABLED = 7;
final byte TIMER_SET_TIME = 8;
final byte METRONOME_ENABLED = 9;
final byte METRONOME_DISABLED = 10;
final byte METRONOME_SET_DURATION = 11;
final byte LIGHT_SET_COLOR = 12;
final byte REALIZED = 13;
final byte SKIP_ALARM_CLOCK = 14;

final int HOUR = 3600000;
final int MINUTE = 60000;
final int SECOND = 1000;

final byte STRIP_LENGTH = 40;
final int MAX_PING = 1000;

Window error;

Window[] windows;
Window update;

OutputStream out;
InputStream in;

int position = 0;
boolean move = false;
long mark;

int mouse_x;

PFont big, medium, small;

void setup() {
  orientation(PORTRAIT);
  imageMode(CENTER);
  textAlign(CENTER, CENTER);
  rectMode(QUAD);

  big = createFont("SansSerif-Bold", width/5);
  medium = createFont("SansSerif-Bold", width/10);
  small = createFont("Monospaced", width/20);
  
  update = error = new Error();
  windows = new Window[]{new AlarmClock(), new TimerWindow(), new Metronome(), new LightPicker()};
}

void connect(){
  println("try connection");
  try{
    InetSocketAddress lampIP = new InetSocketAddress("192.168.4.1", 10);
    Socket socket = new Socket();
    socket.connect(lampIP, 1000);
    
    in = socket.getInputStream();
    out = socket.getOutputStream();
    write(new byte[]{SETTINGS});  //отправка команды
    
    for(Window w: windows)        //для каждого окна (будильник, метроном, ...)
      w.loadSettings();           //импортируем данные
      
    update = windows[position];
    write(new byte[]{SKIP_ALARM_CLOCK});
  }catch(Exception e){  }
}

int available(){
 try{
  return in.available(); 
 }catch(Exception e){
   return 0;
 }
}

int loop(float n, int begin, int end) {
  int N = (int)n;                        //не целое число превращаем в целое
  if (N < begin)
    return end+N-begin;
  else if(N >= end)
    return N-end+begin;
    
  return N;
}

float angle(float x1, float y1, float x2, float y2){
  return -atan2(x1 - x2, y1 - y2) + HALF_PI;  
}
void draw() {
  background(#ECECEC);  //окрашиваем фон белым цветом

  if (move){
    translate(mouseX - mouse_x - width, 0);
    windows[position == 0? windows.length - 1 : position - 1].draw();
    
    translate(width, 0);
    windows[position].draw();
    
    translate(width, 0);
    windows[(position + 1) % windows.length].draw();
  }
  else{
    update.update();
    update.draw();
  }
}

void write(byte[] message){
   try{
     out.write(message); 
     mark = millis() + MAX_PING;
     
     while(in.available() == 0){
       if(mark - millis() < 0){
         update = error;
         return; 
       }
     }
     
     in.skip(1);
     
   }catch(Exception e){  }
}

int read(){
  try{
    return in.read();
  }catch(Exception e){
    return -1;
  }
}

void mousePressed() {
  write(new byte[]{SKIP_ALARM_CLOCK});
  
  if (update.touched()) {
    mouse_x = mouseX;
    move = update != error;
  }
}
void mouseReleased() {
  if (move) {
    position = loop(position + constrain(2 * (mouse_x - mouseX) / width, -1, 1), 0, windows.length);
    update = windows[position];
    move = false;
  }
}
void keyPressed() {
  print();
}
