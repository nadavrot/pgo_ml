// csc 473 more interesting box

camera {
  location  <0, 0, 14>
  up        <0,  1,  0>
  right     <1.5, 0,  0>
  look_at   <0, 0, 0>
}

light_source {<10, 10, 3> color rgb <1.0, 1.0, 1.0>}


// Floor
plane {<0, 1, 0>, -4
  pigment {color rgb <0.6, 0.3, 0.6>}
  finish {ambient 0.4 diffuse 1.0}
}

// Background
plane {<0, 0, 1>, -100
  pigment {color rgb <0.8, 0.6, 0.4>}
  finish {ambient 0.2 diffuse 0.4}
}


box {<-2, -5, -4.5>, <2, 5, 4.5>
  pigment { color rgb <1.0, 1.0, 1.0>}
  finish {ambient 0.2 diffuse 0.8 reflection 0.8}
  rotate <0, -45, 0>
  translate <-7, 0, -5>
}

box {<-2, -5, -4.5>, <2, 5, 4.5>
  pigment { color rgb <1.0, 1.0, 1.0>}
  finish {ambient 0.2 diffuse 0.8 reflection 0.8}
  rotate <0, 45, 0>
  translate <7, 0, -5>
}

box {<-1, -1, -1>, <1, 1, 1>
  pigment { color rgb <0.9, 0.2, 0.3>}
  finish {ambient 0.2 diffuse 0.8}
  translate <0, -3, -3>
}

box {<-1, -1, -1>, <1, 1, 1>
  pigment { color rgb <0.5, 0.9, 0.2>}
  finish {ambient 0.2 diffuse 0.8}
  translate <4, -3, 0>
}

box {<-1, -1, -1>, <1, 1, 1>
  pigment { color rgb <0.2, 0.6, 0.8>}
  finish {ambient 0.2 diffuse 0.8}
  translate <-4, -3, 0>
}
