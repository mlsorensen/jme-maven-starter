package org.example;

import com.jme3.app.SimpleApplication;
import com.jme3.math.ColorRGBA;

/**
 * The absolute smallest JME “Hello‑World”.
 * It opens a window and clears it to a light‑blue colour.
 */
public class App extends SimpleApplication {

    public static void main(String[] args) {
        // The Maven Exec plugin (or IntelliJ) will call this.
        new App().start();               // boots the engine → simpleInitApp()
    }

    @Override
    public void simpleInitApp() {
        viewPort.setBackgroundColor(ColorRGBA.Blue.mult(0.5f));
        System.out.println("jME is up and running!");
    }
}
