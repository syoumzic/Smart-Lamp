abstract class Bar {  //пустой родительский класс
  void loadSettings() {}
  void draw() {}
  boolean touched() { return false; }                  //все функции служат для переопределения в дочерние классы
  void init() {}
  void update() {}
}
//-------------------------------------------------------------
class Window{  //родительский класс
  Bar[] bars;
  Bar update;
  
  void loadSettings(){  };
  
  void update(){
    if (mousePressed && update != null)
      update.update();      //гарантированное исполнение при выборе какой-либо сноски
  }
  
  void draw() {
    for (Bar b : bars)
      b.draw();
  }

  boolean touched() {
    update = null;
    for (Bar b : bars)
      if (b.touched()) {
        update = b;
        update.init();
        return false;
      }
    return true;
  }
  
  void exact(Button b){  }
  void exact(Picker p){  }
  void exact(Scroll s){  }
  void exact(ColorWheel w){  }
}
