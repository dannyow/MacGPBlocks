//
//  glfwPrims.c
//
//  Created by Daniel Owsiański on 22/11/2021.
//

#ifdef __APPLE__
#define GL_SILENCE_DEPRECATION
#endif

// GLFW_INCLUDE_GLCOREARB makes the GLFW header include the modern OpenGL
#define GLFW_INCLUDE_GLCOREARB
#include <GLFW/glfw3.h>

#include <stdio.h>
#include <stdlib.h>  // EXIT_SUCCESS, EXIT_FAILURE

#include "mem.h"
#include "interp.h"


static int initialized = false;
GLFWwindow* window = NULL;

// Used by events.c
int mouseScale;
int windowWidth;
int windowHeight;

#define TODO(s) printf("TODO: " s "(%s:%d)\n", __FILE__, __LINE__)
#define WARN(s) printf("WARN: " s "(%s:%d)\n", __FILE__, __LINE__)

static void exitHandler(void){
    WARN("Called at exit");
    glfwTerminate();
}
static void initGraphics() {
    if (initialized) return; // already initialized

    if (!glfwInit()) {
        fprintf(stderr, "Failed to initialize GLFW\n");
        exit(EXIT_FAILURE);
    }

    atexit(exitHandler);

    initialized = true;
}

OBJ primOpenWindow(int nargs, OBJ args[]) {
    int w = intOrFloatArg(0, 500, nargs, args);
    int h = intOrFloatArg(1, 500, nargs, args);

    int useHighDPIFlag = ((nargs > 2) && (args[2] == trueObj)) ? 1 : 0;
    char *title = strArg(3, "GP", nargs, args);

    int screenBufferFlag = (nargs > 4) && (trueObj == args[4]); // use bitmap screen buffer
    printf("WARN: >screenBufferFlag< won't be used (%s:%d)\n", __FILE__, __LINE__);

    w = clip(w, 10, 5000);
    h = clip(h, 10, 5000);

    initGraphics();

    if (window) {
        // if window is already open, just resize it
//        SDL_SetWindowSize(window, w, h);
//        createOrUpdateOffscreenBitmap(false);
        TODO("resize window if already opened.");
        return nilObj;
    }

    window = glfwCreateWindow(w, h, title, NULL, NULL);
    if (!window) {
        fprintf(stderr, "Failed to open GLFW window\n");
        exit(EXIT_FAILURE);
    }

    glfwMakeContextCurrent(window);
    int actualW, logicalW, actualH, logicalH;
    float contentScaleX, contentScaleY;
    glfwGetWindowSize(window, &logicalW, &logicalH);
    glfwGetWindowContentScale(window, &contentScaleX, &contentScaleY);
    actualW = logicalW * contentScaleX;
    actualH = logicalH * contentScaleY;

    windowWidth = actualW;
    windowHeight = actualH;

    return nilObj;

}
OBJ primWindowSize(int nargs, OBJ args[]) {

    int actualW, logicalW, actualH, logicalH;
    float contentScaleX, contentScaleY;
    glfwGetWindowSize(window, &logicalW, &logicalH);
    glfwGetWindowContentScale(window, &contentScaleX, &contentScaleY);
    actualW = logicalW * contentScaleX;
    actualH = logicalH * contentScaleY;

    OBJ result = newArray(4);
    FIELD(result, 0) = int2obj(logicalW);
    FIELD(result, 1) = int2obj(logicalH);
    FIELD(result, 2) = int2obj(actualW);
    FIELD(result, 3) = int2obj(actualH);

    return result;
}

OBJ primNextEvent(int nargs, OBJ args[]) {
    if(window){
        glfwSwapBuffers(window);
    }
    return getEvent();
}


OBJ primFillRect(int nargs, OBJ args[]) {
    //return primFailed("Forced trap in primFillRect ");
    return nilObj;}
OBJ primFlipWindowBuffer(int nargs, OBJ args[]) {return nilObj;}


OBJ primCloseWindow(int nargs, OBJ args[]) {return nilObj;}
OBJ primSetFullScreen(int nargs, OBJ args[]) {return nilObj;}
OBJ primSetWindowTitle(int nargs, OBJ args[]) {return nilObj;}

OBJ primSetCursor(int nargs, OBJ args[]) {return nilObj;}


// ***** Graphics Primitive Lookup *****

PrimEntry graphicsPrimList[] = {
    {"-----", NULL, "Graphics: Windows"},
    {"openWindow",        primOpenWindow,                "Open the graphics window. Arguments: [width height tryRetinaFlag title]"},
    {"closeWindow",        primCloseWindow,            "Close the graphics window."},
//    {"clearBuffer",        primClearWindowBuffer,        "Clear the offscreen window buffer to a color. Ex. clearBuffer (color 255 0 0); flipBuffer"},
//    {"showTexture",        primShowTexture,            "Draw the given texture. Draw to window buffer if dstTexture is nil. Arguments: dstTexture srcTexture [x y alpha xScale yScale rotationDegrees flip blendMode clipRect]"},
    {"flipBuffer",        primFlipWindowBuffer,        "Flip the onscreen and offscreen window buffers to make changes visible."},
    {"windowSize",        primWindowSize,                "Return an array containing the width and height of the window in logical and physical (high resolution) pixels."},
    {"setFullScreen",    primSetFullScreen,            "Set full screen mode. Argument: fullScreenFlag"},
    {"setWindowTitle",    primSetWindowTitle,            "Set the graphics window title to the given string."},
    {"-----", NULL, "Graphics: Textures"},
//    {"createTexture",    primCreateTexture,            "Create a reference to new texture (a drawing surface in graphics memory). Arguments: width height [fillColor]. Ex. ref = (createTexture 100 100)"},
//    {"destroyTexture",    primDestroyTexture,            "Destroy a texture reference. Ex. destroyTexture ref"},
//    {"readTexture",        primReadTexture,            "Copy the given texture into the given bitmap. Arguments: bitmap texture"},
//    {"updateTexture",    primUpdateTexture,            "Update the given texture from the given bitmap. Arguments: texture bitmap"},
    {"-----", NULL, "Graphics: Drawing"},
    {"fillRect",        primFillRect,                "Draw a rectangle. Draw to window buffer if textureOrBitmap is nil. Arguments: textureOrBitmap color [x y width height blendMode]."},
//    {"drawBitmap",        primDrawBitmap,                "Draw a bitmap. Draw to window buffer if textureOrBitmap is nil. Arguments: textureOrBitmap srcBitmap [x y alpha blendMode clipRect]"},
//    {"warpBitmap",        primWarpBitmap,                "Scaled and/or rotate a bitmap. Arguments: dstBitmap srcBitmap [centerX centerY scaleX scaleY rotation]"},
//    {"drawLineOnBitmap", primDrawLineOnBitmap,        "Draw a line on a bitmap. Only 1-pixel anti-aliased lines are supported. Arguments: dstBitmap x1 y1 x2 y2 [color lineWidth antiAliasFlag]"},
    {"-----", NULL, "User Input"},
    {"nextEvent",        primNextEvent,                "Return a dictionary representing the next user input event, or nil if the queue is empty."},
//    {"getClipboard",    primGetClipboard,            "Return the string from the clipboard, or the empty string if the cliboard is empty."},
//    {"setClipboard",    primSetClipboard,            "Set the clipboard to the given string."},
//    {"showKeyboard",    primShowKeyboard,            "Show or hide the on-screen keyboard on a touchsceen devices. Argument: true or false."},
    {"setCursor",        primSetCursor,                "Change the mouse pointer appearance. Argument: cursorNumber (0 -> arrow, 3 -> crosshair, 11 -> hand...)"},
};

PrimEntry* pocPrimitives(int *primCount) {
    *primCount = sizeof(graphicsPrimList) / sizeof(PrimEntry);
    return graphicsPrimList;
}
