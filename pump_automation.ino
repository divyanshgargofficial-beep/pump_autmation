#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <ESP8266mDNS.h>

#define RELAY_PIN 5          // D1
#define WATER_SENSOR_PIN 0   // D3

const char* ssid = "Airtel_divy_7892_2.4Ghz";
const char* password = "air72986";
const char* mdnsName = "watertank";

ESP8266WebServer server(80);

bool pumpRunning = false;
bool tankFull = false;
bool lockout = false;
unsigned long pumpStartedAt = 0;

void writePump(bool running)
{
    digitalWrite(RELAY_PIN, running ? LOW : HIGH); // Relay is active low.
    pumpRunning = running;

    if (running)
    {
        pumpStartedAt = millis();
    }
    else
    {
        pumpStartedAt = 0;
    }
}

unsigned long runtimeSeconds()
{
    if (!pumpRunning || pumpStartedAt == 0)
    {
        return 0;
    }

    return (millis() - pumpStartedAt) / 1000;
}

String statusJson(bool success = true)
{
    String json = "{";
    json += "\"success\":";
    json += success ? "true" : "false";
    json += ",\"wifiConnected\":";
    json += WiFi.status() == WL_CONNECTED ? "true" : "false";
    json += ",\"pump\":";
    json += pumpRunning ? "true" : "false";
    json += ",\"tankFull\":";
    json += tankFull ? "true" : "false";
    json += ",\"lockout\":";
    json += lockout ? "true" : "false";
    json += ",\"runtime\":";
    json += runtimeSeconds();
    json += "}";
    return json;
}

void sendJson(int statusCode, const String& body)
{
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(statusCode, "application/json", body);
}

void sendNotFound()
{
    sendJson(404, "{\"success\":false,\"error\":\"not_found\"}");
}

void handleStatus()
{
    sendJson(200, statusJson());
}

void handleOn()
{
    if (lockout)
    {
        sendJson(423, "{\"success\":false,\"error\":\"lockout_active\"}");
        return;
    }

    if (tankFull)
    {
        lockout = true;
        writePump(false);
        sendJson(409, "{\"success\":false,\"error\":\"tank_full\"}");
        return;
    }

    writePump(true);
    sendJson(200, "{\"success\":true}");
}

void handleOff()
{
    writePump(false);
    sendJson(200, "{\"success\":true}");
}

void handleReset()
{
    lockout = false;
    writePump(false);
    sendJson(200, "{\"success\":true}");
}

void updateTankState()
{
    bool detectedFull = digitalRead(WATER_SENSOR_PIN) == LOW; // INPUT_PULLUP: water = LOW.
    tankFull = detectedFull;

    if (detectedFull)
    {
        if (pumpRunning)
        {
            writePump(false);
        }

        lockout = true;
    }
}

void connectWiFi()
{
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);

    Serial.print("Connecting to WiFi");
    while (WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(".");
    }

    Serial.println();
    Serial.print("Connected. IP: ");
    Serial.println(WiFi.localIP());

    if (MDNS.begin(mdnsName))
    {
        MDNS.addService("http", "tcp", 80);
        Serial.print("mDNS started: http://");
        Serial.print(mdnsName);
        Serial.println(".local");
    }
    else
    {
        Serial.println("mDNS start failed");
    }
}

void setupRoutes()
{
    server.on("/", HTTP_GET, handleStatus);
    server.on("/status", HTTP_GET, handleStatus);
    server.on("/on", HTTP_GET, handleOn);
    server.on("/off", HTTP_GET, handleOff);
    server.on("/reset", HTTP_GET, handleReset);
    server.onNotFound(sendNotFound);
    server.begin();
}

void setup()
{
    Serial.begin(115200);

    pinMode(RELAY_PIN, OUTPUT);
    pinMode(WATER_SENSOR_PIN, INPUT_PULLUP);
    writePump(false);

    connectWiFi();
    setupRoutes();
}

void loop()
{
    updateTankState();
    server.handleClient();
    MDNS.update();
}
