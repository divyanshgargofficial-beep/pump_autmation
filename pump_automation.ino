#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>

#define RELAY_PIN 5          // D1
#define WATER_SENSOR_PIN 0   // D3

const char* ssid = "Airtel_divy_7892_2.4Ghz";
const char* password = "air72986";

ESP8266WebServer server(80);

bool lightState = false;
bool tankFull = false;

unsigned long onStart = 0;

// ==================================================
String webpage()
{
    float seconds = 0;

    if (lightState)
    {
        seconds = (millis() - onStart) / 1000.0;
    }

    String page =
        "<!DOCTYPE html><html><head>"
        "<meta name='viewport' content='width=device-width, initial-scale=1'>"
        "<meta http-equiv='refresh' content='1'>"

        "<style>"
        "body{font-family:Arial;text-align:center;margin-top:40px;}"
        "button{width:140px;height:60px;font-size:22px;margin:10px;border:none;border-radius:12px;}"
        ".on{background:#4CAF50;color:white;}"
        ".off{background:#f44336;color:white;}"
        "</style>"

        "</head><body>";

    page += "<h2>Water Tank Controller</h2>";

    page += "<h3>Motor State: ";
    page += (lightState ? "ON" : "OFF");
    page += "</h3>";

    page += "<h3>Tank Status: ";
    page += (tankFull ? "FULL" : "FILLING");
    page += "</h3>";

    page += "<h3>Run Time: ";
    page += String(seconds, 1);
    page += " sec</h3>";

    page += "<a href='/on'><button class='on'>ON</button></a>";
    page += "<a href='/off'><button class='off'>OFF</button></a>";

    page += "</body></html>";

    return page;
}

// ==================================================
void handleRoot()
{
    server.send(200, "text/html", webpage());
}

// ==================================================
void handleOn()
{
    if (tankFull)
    {
        server.send(200, "text/html", webpage());
        return;
    }

    if (!lightState)
    {
        lightState = true;
        onStart = millis();
    }

    digitalWrite(RELAY_PIN, LOW); // ON (active low)

    server.send(200, "text/html", webpage());
}

// ==================================================
void handleOff()
{
    digitalWrite(RELAY_PIN, HIGH); // OFF

    lightState = false;
    onStart = 0;

    server.send(200, "text/html", webpage());
}

// ==================================================
void detection()
{
    // INPUT_PULLUP:
    // Dry  = HIGH
    // Water = LOW

    if (digitalRead(WATER_SENSOR_PIN) == LOW)
    {
        tankFull = true;

        digitalWrite(RELAY_PIN, HIGH); // OFF

        lightState = false;
        onStart = 0;
    }
    else
    {
        tankFull = false;
    }
}

// ==================================================
void setup()
{
    Serial.begin(115200);

    pinMode(RELAY_PIN, OUTPUT);
    pinMode(WATER_SENSOR_PIN, INPUT_PULLUP);

    // Relay OFF at startup
    digitalWrite(RELAY_PIN, HIGH);

    WiFi.begin(ssid, password);

    Serial.print("Connecting");

    while (WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(".");
    }

    Serial.println();
    Serial.print("Connected! Open: http://");
    Serial.println(WiFi.localIP());

    server.on("/", handleRoot);
    server.on("/on", handleOn);
    server.on("/off", handleOff);

    server.begin();
}

// ==================================================
void loop()
{
    server.handleClient();

    detection();
}