package org.example;

import com.jme3.app.SimpleApplication;
import com.jme3.math.ColorRGBA;

/**
 * Hello world!
 *
 */
public class App extends SimpleApplication {
    public static void main(String[] args) {
        // The Exec plugin will invoke this method.
        new App().start();   // start() boots the engine and calls simpleInitApp()
    }

    @Override
    public void simpleInitApp() {
        // Set a background colour so we can see the window is alive.
        viewPort.setBackgroundColor(ColorRGBA.Blue.mult(0.5f));

        // Print something to the console – proves the Java side works.
        System.out.println("jME is up and running!");
    }
}
