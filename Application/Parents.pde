abstract class Bar {  //пустой родительский класс
  void windowDraw(){  }
  void loadSettings() {}
  void draw() { }
  boolean touched() { return false;  }
  void mousePressed() {  }
  void init() {  }
  void update() {  }
  void mouseReleased(){  }
}
//-------------------------------------------------------------
class Window extends Bar {  //родительский класс
  Bar[] bars;

  void loadSettings() {  };

  void update() {
      translate(mouseX - mouse_x - width, 0);
      windows[position == 0? windows.length - 1 : position - 1].draw();

      translate(2*width, 0);
      windows[(position + 1) % windows.length].draw();
      
      translate(-width, 0);  //for window
  }

  void draw() {
    for (Bar b : bars)
      b.draw();
  }

  void mousePressed() {
    for (Bar b : bars)
      if (b.touched()) {
        update = b;
        update.init();
        return;
      }
      
    update = window;
    mouse_x = mouseX;  //init()
  }
  
  void mouseReleased(){
    position = loop(position + (mouseX - mouse_x < -SWIPE_LENGTH? 1 : (mouseX - mouse_x > SWIPE_LENGTH)? -1 : 0), 0, windows.length);
    window = windows[position];
  }

  void exact(Button b) {  }
  void exact(Picker p) {  }
  void exact(Scroll s) {  }
  void exact(ColorWheel w) {  }
}
