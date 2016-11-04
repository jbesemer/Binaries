// NeoPixel Ring simple sketch (c) 2013 Shae Erisson
// released under the GPLv3 license to match the rest of the AdaFruit NeoPixel library
#include <Adafruit_NeoPixel.h>

// Which pin on the Arduino is connected to the NeoPixels?
#define PIN            0

// How many NeoPixels are attached to the Arduino?
#define NUMPIXELS      4

// Teensy 3.0 has the LED on pin 13
const int ledPin = 13;

// When we setup the NeoPixel library, we tell it how many pixels, and which pin to use to send signals.
// Note that for older NeoPixel pixels you might need to change the third parameter--see the strandtest
// example for more information on possible values.
//  Parameter 1 = number of pixels in pixel
//  Parameter 2 = Arduino pin number (most are valid)
//  Parameter 3 = pixel type flags, add together as needed:
//  NEO_KHZ800  800 KHz bitstream (most NeoPixel products w/WS2812 LEDs)
//  NEO_KHZ400  400 KHz (classic 'v1' (not v2) FLORA pixels, WS2811 drivers)
//  NEO_GRB     Pixels are wired for GRB bitstream (most NeoPixel products)
//  NEO_RGB     Pixels are wired for RGB bitstream (v1 FLORA pixels, not v2)
Adafruit_NeoPixel pixels = Adafruit_NeoPixel(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);

int delayval = 500; // delay for half a second

void setup() {
  pixels.begin(); // This initializes the NeoPixel library.
  pinMode(ledPin, OUTPUT); // initialize the digital pin as an output.
}

void loop() {
  // For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.
  for(int i=0;i<NUMPIXELS;i++){
    // pixels.Color takes RGB values, from 0,0,0 up to 255,255,255

 //   pixels.setPixelColor(0, pixels.Color(32,0,0)); // Dim red.
 //   pixels.show(); // This sends the updated pixel color to the hardware.
 //   digitalWrite(ledPin, HIGH);   // set the LED on
 //   delay(delayval);                  // wait for a second
    
 //   pixels.setPixelColor(0, pixels.Color(0,32,0)); // Dim green.
 //   pixels.show(); // This sends the updated pixel color to the hardware.    
    digitalWrite(ledPin, LOW);    // set the LED off
 //   delay(delayval);                  // wait for a second
//    delay(delayval); // Delay for a period of time (in milliseconds).

  rainbow(20);

  }
} 
  
void rainbow(uint8_t wait) {
  uint16_t i, j;

  for(j=0; j<256; j++) {
    for(i=0; i<pixels.numPixels(); i++) {
      pixels.setPixelColor(i, Wheel((i+j) & 255));
    }
    pixels.show();
    delay(wait);
  }
}  
  
  
// Input a value 0 to 255 to get a color value.
// The colours are a transition r - g - b - back to r.
uint32_t Wheel(byte WheelPos) {
  WheelPos = 255 - WheelPos;
  if(WheelPos < 85) {
   return pixels.Color(255 - WheelPos * 3, 0, WheelPos * 3);
  } else if(WheelPos < 170) {
    WheelPos -= 85;
   return pixels.Color(0, WheelPos * 3, 255 - WheelPos * 3);
  } else {
   WheelPos -= 170;
   return pixels.Color(WheelPos * 3, 255 - WheelPos * 3, 0);
  }
}   
  


