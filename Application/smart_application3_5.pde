import java.net.InetSocketAddress;
import java.net.Socket;

String lampIp = "192.168.1.117";
float SWIPE_LENGTH = .3;  // * width

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

Bar update;
Window window;

Socket socket;
OutputStream out;
InputStream in;

int position = 0;      //позиция стартового окна
long mark;
int mouse_x;
boolean connect; 

PFont big, medium, small;

void setup() {
  size(400, 700);
  imageMode(CENTER);
  textAlign(CENTER, CENTER);
  rectMode(QUAD);

  big = createFont("SansSerif-Bold", width/5);
  medium = createFont("SansSerif-Bold", width/10);
  small = createFont("Monospaced", width/22);
  
  error = new Error();
  windows = new Window[]{new AlarmClock(), new TimerWindow(), new Metronome(), new LightPicker()};
  window = connect()? windows[position] : error;
  
  SWIPE_LENGTH *= width;
}

boolean connect(){
  try{
    InetSocketAddress lampIP = new InetSocketAddress(lampIp, 10);
    socket = new Socket();
    socket.connect(lampIP, 2000);
    
    in = socket.getInputStream();
    out = socket.getOutputStream();
    write(new byte[]{SETTINGS});  //отправка команды
    
    for(Window w: windows)        //для каждого окна (будильник, метроном, ...)
      w.loadSettings();           //импортируем данные
      
    window = windows[position];
    write(new byte[]{SKIP_ALARM_CLOCK});
    connect = true;
  }
  catch(Exception e){ 
    connect = false;
    return false;
  }
  return true;
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

void draw(){
  if(!focused && connect){
    try{  
      socket.close();
      connect = false;
    } catch(IOException e){}
  }
  else if(focused && !connect){
    window = connect()? windows[position] : error;
  }
  
  background(#ECECEC);
  
  if(mousePressed)
    update.update();
  window.draw();
}

void write(byte[] message){
   try{
     out.write(message); 
     mark = millis() + MAX_PING;
     
     while(in.available() == 0)
       if(mark - millis() < 0){
         window = error;
         return; 
       }
      println(read());
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
  window.mousePressed();
}
void mouseReleased() {
  update.mouseReleased();
}
void keyPressed() {
  print();
}
