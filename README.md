# jMonkeyEngine 3.8 starter with Maven

A **minimal, self-contained Maven project** that shows how to:

* pull the jMonkeyEngine (jME) libraries,
* compile a tiny “Hello-World” JME application,
* run it directly from the IntelliJ IDE or with `mvn exec:java`,
* create a **single runnable (uber) JAR** with the Maven Shade plugin.

Yes, this could and would probably be better as a Maven archetype.

---  

## Table of Contents

| Section                                                 | What you’ll find                                     |
|---------------------------------------------------------|------------------------------------------------------|
| [Prerequisites](#prerequisites)                         | JDK, Maven, IntelliJ (optional)                      |
| [Project layout](#project-layout)                       | Where the files live                                 |
| [The Maven build](#the-maven-build)                     | `pom.xml` highlights                                 |
| [Run from the command line](#run-from-the-command-line) | `mvn compile exec:java`                              |
| [Run from IntelliJ IDEA](#run-from-intellij-IDEA)       | Pre-configured **Run** and **Package** configs       |
| [Build the uber-JAR](#build-the-uber-jar)               | `mvn package` → `target/my-jme-app-1.0.0-shaded.jar` |
| [Run the shaded JAR](#run-the-shaded-jar)               | `java -jar …`                                        |
| [Changing the main class](#changing-the-main-class)     | How to point to a different class                    |
| [FAQ / Troubleshooting](#faq--troubleshooting)          | Common hiccups                                       |
| [Using `customize.sh`](#using-customizesh)              | One-command project customization                    |
| [License](#license)                                     | MIT                                                  |

---  

## Prerequisites

| Tool                                         | Minimum version                                                           | Why                                                                                       |
|----------------------------------------------|---------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| **JDK**                                      | **24** (or any later JDK) – set in `<maven.compiler.source>` / `<target>` | Java 24 is the default JRE in IntelliJ                                                    |
| **Maven**                                    | 3.9+                                                                      | Used for compilation, shading and the `exec` plugin                                       |
| **IntelliJ IDEA** (optional but recommended) | 2024.2+                                                                   | IDE import is a one-click Maven project; the repo already contains two run configurations |

> **Tip** – If you only have JDK 17/21 installed you can still compile the project by changing the `<maven.compiler.source>` and `<target>` properties to that version – the engine itself works on older JDKs, but the POM shipped with
this repo targets the newest JDK to show “future-proof” syntax.

---  

## Project layout

```
my-jme-app/
│
├─ pom.xml                     ← Maven descriptor (see below)
│
└─ src/
   └─ main/
      └─ java/
         └─ org/
            └─ example/
               └─ App.java    ← Minimal JME application (see snippet)
```

### `src/main/java/org/example/App.java`

```java
package org.example;

import com.jme3.app.SimpleApplication;
import com.jme3.math.ColorRGBA;

/**
 * The absolute smallest JME “Hello-World”.
 * It opens a window and clears it to a light-blue colour.
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
```

Feel free to replace the content with your own game logic – just keep the `main` method that calls `new App().start();`.

---  

## The Maven build

Below is a **high-level walk-through** of the important parts of `pom.xml`.  
(The full file is already in the repository.)

| Section                   | What it does                                                                                                                            |
|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| **Project coordinates**   | `groupId`, `artifactId`, `version` – the Maven coordinates of the artifact                                                              |
| **Java version**          | `<maven.compiler.source>` / `<target>` set to **24** (you can change them)                                                              |
| **`mainClass` property**  | Centralised reference to the entry point (`org.example.App`)                                                                            |
| **Dependencies**          | `jme3-core`, `jme3-desktop`, `jme3-lwjgl3` (the default desktop backend)                                                                |
| **Shade plugin**          | Packages **all** dependencies (including native LWJGL binaries) into one JAR and writes the `Main-Class` attribute using `${mainClass}` |
| **Exec Maven plugin**     | Allows `mvn exec:java` (or the IntelliJ **Run** config) to start the app without building a JAR first                                   |
| **Maven compiler plugin** | Uses the Java version defined in the properties                                                                                         |

---  

## Run from the command line

```bash
# 1️⃣ Compile (creates target/classes)
mvn compile

# 2️⃣ Run the app directly (no JAR needed)
mvn exec:java
```

You should see:

```
jME is up and running!
```

…and a window with a light-blue background.

---  

## Run from IntelliJ IDEA

The repository already contains two **Run/Debug Configurations** (they are stored in `.idea/runConfigurations/`).

| Config name | What it does                                                                                                 |
|-------------|--------------------------------------------------------------------------------------------------------------|
| **Run**     | Executes the `exec:java` goal – identical to `mvn exec:java`                                                 |
| **Package** | Runs `mvn package` (Shade plugin) and then launches the generated JAR (`target/my-jme-app-1.0.0-shaded.jar`) |

### One-click workflow

1. **Open the project** – IntelliJ will detect the `pom.xml` and ask to *Import Maven projects*. Accept.
2. In the **Run** toolbar, select **Run** → **Run ‘Run’** (or press **Shift-F10**).  
   *The console shows the same “jME is up and running!” line and the window appears.*
3. To build the uber-JAR, select **Package** → **Run ‘Package’** (or press **Ctrl-Shift-F10**). After the build finishes, the JAR lives in `target/`.

---  

## Build the uber-JAR

```bash
mvn clean package
```

What you get:

```
target/
 └─ my-jme-app-1.0.0-shaded.jar   ← runnable JAR (includes native libs)
```

The Shade plugin merges the `META-INF/services` files that jME uses for its Service Provider Interface (SPI), so the JAR works out-of-the-box.

---  

## Run the shaded JAR

```bash
java -jar target/my-jme-app-1.0.0-shaded.jar
```

You should see exactly the same output and window as when running via Maven/IDE.
> **Tip:** Because the JAR contains the native LWJGL binaries, you **don’t need** any external `-Djava.library.path` settings.

---  

## Changing the main class

If you want to point the build/run process to a different entry point, edit the `<mainClass>` property in `pom.xml` (or change the class name referenced by the Exec plugin). The value must be the fully-qualified name of the class
that contains `public static void main(String[] args)`.

---  

## Customising the Maven Project (coordinates, package, main class, etc.)

Below are the **exact places** you have to edit when you turn this starter into *your own* jMonkeyEngine game.

| What you want to change                                                                                                               | Where to edit                                                                                                    | What to put                                                                                                                                                    |
|---------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Maven coordinates** (group-id, artifact-id, version)                                                                                | `pom.xml` → `<groupId>`, `<artifactId>`, `<version>`                                                             | Use a unique reverse-domain name for the group-id (e.g. `com.mycompany.game`). Pick an artifact-id that matches the                                            |
| repo name (`my-awesome-game`). Increment the version when you release (`1.0.0`, `1.1.0-SNAPSHOT`, …).                                 |                                                                                                                  |                                                                                                                                                                |
| **Java package of your code**                                                                                                         | `src/main/java/…` folder hierarchy                                                                               | Move the existing `org/example/App.java` to the package you want, e.g. `com/mycompany/game/Main.java`. Update the `package` declaration at the top of the file |
| accordingly.                                                                                                                          |                                                                                                                  |                                                                                                                                                                |
| **Main (entry-point) class**                                                                                                          | `pom.xml` → `<properties><mainClass>…</mainClass></properties>` (and optionally the Exec plugin)                 | Set it to the fully-qualified name of the class that contains `public static void main(String[]                                                                |
| args)`. Example: `<mainClass>com.mycompany.game.Main</mainClass>`.                                                                    |                                                                                                                  |                                                                                                                                                                |
| **Application name shown in the window**                                                                                              | Inside your `SimpleApplication` subclass (`App`/`Main`) → `setTitle("…")` or `appSettings.setTitle("…")`         | Change `"My-JME-App"` to whatever you like.                                                                                                                    |
| **Output JAR name** (optional)                                                                                                        | `pom.xml` → `<finalName>` inside the `<build>` section (or let Maven use the default `${artifactId}-${version}`) | If you want a custom JAR name, add `<finalName>MyGame</finalName>` under `<build>`.                                                                            |
|
| **Additional dependencies** (e.g., physics, UI)                                                                                       | `pom.xml` → `<dependencies>` block                                                                               | Add the Maven coordinates of the extra jME modules, e.g.                                                                                                       |
| `<dependency><groupId>org.jmonkeyengine</groupId><artifactId>jme3-bullet</artifactId><version>${jme.version}</version></dependency>`. |                                                                                                                  |                                                                                                                                                                |
| **Java version used for compilation**                                                                                                 | `pom.xml` → `<properties><maven.compiler.source>` / `<maven.compiler.target>`                                    | Set both to the JDK you want to target (e.g. `11`, `17`, `21`). Keep them the same value.                                                                      |
| **Shade plugin exclusions / filters** (if you want a smaller JAR)                                                                     | `pom.xml` → `<plugin><artifactId>maven-shade-plugin</artifactId>` → `<filters>`                                  | Add `<exclude>**/some/large/resource/**</exclude>` entries to drop unnecessary                                                                                 |
| assets.                                                                                                                               |                                                                                                                  |                                                                                                                                                                |

### Step-by-step example

1. **Open `pom.xml`** and change the coordinates:

   ```xml
   <groupId>com.mycompany.game</groupId>
   <artifactId>awesome-space-shooter</artifactId>
   <version>0.1.0-SNAPSHOT</version>
   ```

2. **Move the source file**

   ```bash
   # from
   src/main/java/org/example/App.java
   # to
   src/main/java/com/mycompany/game/Main.java
   ```

   Edit the file header:

   ```java
   package com.mycompany.game;   // <-- new package
   ```

3. **Tell Maven the new main class**

   ```xml
   <properties>
       <mainClass>com.mycompany.game.Main</mainClass>
   </properties>
   ```

4. **Re-import (or reload) the Maven project** in your IDE so it picks up the new package structure.

That’s it – after those few edits the starter is fully yours! 🚀

---  

## Using `customize.sh`

`customize.sh` is a tiny helper that updates **all** of the places you normally have to edit manually (coordinates, package, main-class, README, etc.) with a single command.

### 1️⃣ Make the script executable

```bash
chmod +x customize.sh
```

### 2️⃣ Run it

```bash
./customize.sh
```

You will be prompted for the new **groupId**, **artifactId**, **version**, and **Java package**. The script will then:

* rewrite the `<groupId>`, `<artifactId>`, `<version>` and `<mainClass>` entries in `pom.xml`;
* move/rename the starter source file to the chosen package (`…/Main.java`);
* fix the `package` statement and rename the class to `Main`;
* replace the old `README.md` header with a clean version that reflects the new artifact name.

### 3️⃣ After the script finishes

* Refresh/re-import the Maven project in your IDE (IntelliJ will pick up the new coordinates automatically).
* Run the game as before (`mvn exec:java` or the IntelliJ **Run** configuration).

**One-liner (if you already know the values):**

```bash
GROUP_ID=com.mycompany.game  ARTIFACT_ID=awesome-space-shooter  VERSION=0.1.0-SNAPSHOT  PACKAGE=com.mycompany.game  ./customize.sh
```

*(The script will read those environment variables and skip the interactive prompts.)*

---  

## FAQ / Troubleshooting

| Symptom                                              | Likely cause                                                             | Fix                                                                                                            |
|------------------------------------------------------|--------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
| **`Unsupported major.minor version`**                | Running with a JDK older than 24.                                        | Install JDK 24 (or lower `<source>/<target>` to your JDK).                                                     |
| **Window opens but is black**                        | `simpleInitApp()` never executed.                                        | Ensure `new App().start();` is called from `main`.                                                             |
| **`UnsatisfiedLinkError: …`**                        | Native LWJGL libraries not on the classpath.                             | Verify the `jme3-lwjgl3` dependency is present **without** a classifier (it brings the natives automatically). |
| **IntelliJ “Could not find or load main class …”**   | The Maven run configuration is using a different JDK.                    | Set the **Project SDK** and the **Run configuration JRE** to the same JDK (≥ 24).                              |
| **`java -jar …` says “no main manifest attribute”**  | Shade plugin didn’t run (e.g., you used `-DskipShade`).                  | Run `mvn clean package` (no `-DskipShade`).                                                                    |
| **I get a huge JAR (200 MB+) and the app crashes**   | You added optional heavy modules (e.g., `jme3-bullet` with many assets). | Remove unnecessary dependencies or use the **filters** section of the Shade plugin to exclude large            |
| resource folders.                                    |                                                                          |                                                                                                                |
| **I want to pass command-line arguments to the app** | Not using the Exec plugin or the Shade JAR correctly.                    | For Maven: `mvn exec:java -Dexec.args="arg1 arg2"`. <br>For the JAR: `java -jar … arg1 arg2` (handle them in   |
| `main(String[] args)`).                              |                                                                          |                                                                                                                |

---  

## License

This starter project is released under the **MIT License** – feel free to fork, modify, and ship your own games.

---  

### TL;DR (quick cheat-sheet)

```bash
# Clone & import
git clone https://github.com/yourname/my-jme-app.git
cd my-jme-app

# (Optional) customise the project in one step
./customize.sh   # answer the prompts or set env vars as shown above

# Run directly
mvn compile exec:java

# Build a single JAR
mvn clean package
java -jar target/my-jme-app-1.0.0-shaded.jar
```

Happy coding, and enjoy the 3-D fun with jMonkeyEngine! 🚀  
