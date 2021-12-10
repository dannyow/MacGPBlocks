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

#include "sk_capi.h"

#include "mem.h"
#include "interp.h"

static int initialized = false;
GLFWwindow* window = NULL;
sk_canvas_t* canvas = NULL;
static gr_direct_context_t* context = NULL;
static sk_surface_t* surface = NULL;

static bool needsRepaint = true;

// Used by events.c
int mouseScale;
int windowWidth;
int windowHeight;

#define TODO(s) printf("TODO: " s "(%s:%d)\n", __FILE__, __LINE__)
#define WARN(s) printf("WARN: " s "(%s:%d)\n", __FILE__, __LINE__)


int frames = 0;
double t, t0, fps;
char title_string[20];

static gr_direct_context_t* makeSkiaContext() {
    const gr_glinterface_t* interface = gr_glinterface_create_native_interface();
    gr_direct_context_t* context = gr_direct_context_make_gl(interface);
    return context;
}

static sk_surface_t* newSurface(gr_direct_context_t* context, const int w, const int h) {
    static gr_gl_framebufferinfo_t fbInfo = {
        .fFBOID = 0,
        .fFormat = GL_RGBA8};

    gr_backendrendertarget_t* target = gr_backendrendertarget_new_gl(w, h, 0, 0, &fbInfo);
    sk_color_type_t colorType = SK_COLOR_TYPE_RGBA_8888;

    sk_surface_t* surface = sk_surface_new_backend_render_target(context, target,
                                                                 GR_SURFACE_ORIGIN_BOTTOM_LEFT,
                                                                 colorType, NULL, NULL);
    gr_backendrendertarget_delete(target);
    return surface;
}

static void exitHandler(void) {
    WARN("Called at exit");
    if (context) {
        gr_direct_context_abandon_context(context);
    }
    if (window) {
        glfwDestroyWindow(window);
    }
    glfwTerminate();
}
static void initGraphics() {
    if (initialized) return;  // already initialized

    if (!glfwInit()) {
        fprintf(stderr, "Failed to initialize GLFW\n");
        exit(EXIT_FAILURE);
    }

    atexit(exitHandler);

    initialized = true;
}

static void repaintIfNeeded() {
    if(!needsRepaint){
        return;
    }
    if (canvas) {
        sk_canvas_flush(canvas);
    }
    if (window) {
        glfwSwapBuffers(window);
    }

    if (context) {
        if (surface) {
            sk_surface_unref(surface);
        }
        int actualW, logicalW, actualH, logicalH;
        float contentScaleX, contentScaleY;
        glfwGetWindowSize(window, &logicalW, &logicalH);
        glfwGetWindowContentScale(window, &contentScaleX, &contentScaleY);
        actualW = logicalW * contentScaleX;
        actualH = logicalH * contentScaleY;

        // Surface is cheap(ish?) to create src: https://groups.google.com/g/skia-discuss/c/3c10MvyaSug
        sk_surface_t* surface = newSurface(context, actualW, actualH);
        canvas = sk_surface_get_canvas(surface);
        if (contentScaleX != 1.0 || contentScaleY != 1.0) {
            sk_canvas_scale(canvas, contentScaleX, contentScaleY);
        }
        sk_canvas_draw_color(canvas, 0xFFFFFFFF, SK_BLEND_MODE_SRCOVER);

        ///
        t = glfwGetTime();

        if((t - t0) > 1.0 || frames == 0)
        {
            fps = (double)frames / (t - t0);
            sprintf(title_string, "FPS: %.1f", fps);
            glfwSetWindowTitle(window, title_string);
            t0 = t;
            frames = 0;
        }
        frames ++;
        ///
    }
    needsRepaint = false;
}

OBJ primSkiaRect(int nargs, OBJ args[]) {

    sk_rect_t rect;
    float x = intOrFloatArg(0, 0, nargs, args);
    float y = intOrFloatArg(1, 0, nargs, args);
    rect.left = x;
    rect.top = y;
    rect.right = x + intOrFloatArg(2, 100, nargs, args);
    rect.bottom = y + intOrFloatArg(3, 100, nargs, args);

    int color = intArg(4, 0xFFFF00FF, nargs, args);
    sk_paint_t* paint = sk_paint_new();
    sk_paint_set_style(paint, SK_PAINT_STYLE_STROKE);
    sk_paint_set_stroke_width(paint, 2);
    sk_paint_set_color(paint, color);

    sk_canvas_draw_rect(canvas, &rect, paint);


    sk_paint_delete(paint);
//    needsRepaint = true;

    return nilObj;

}

OBJ primSkiaDraw(int nargs, OBJ args[]) {
    if (!canvas) {
        WARN("No canvas?");

        return nilObj;
    }
    sk_paint_t* paint = sk_paint_new();

    sk_paint_set_color(paint, 0xFF808080);
    sk_canvas_draw_paint(canvas, paint);

    sk_paint_set_color(paint, 0x8FAA0080);
    sk_rect_t rect = {.left = 0, .top = 0, .right = 200, .bottom = 200};
    sk_canvas_draw_rect(canvas, &rect, paint);

    sk_paint_set_color(paint, 0xFFFF0000);
    sk_paint_set_stroke_width(paint, 1);
    sk_canvas_draw_line(canvas, 0, 0, windowWidth, windowHeight, paint);
    sk_canvas_draw_line(canvas, 0, windowHeight * 0.9, windowWidth, windowHeight * 0.9, paint);
    sk_canvas_draw_line(canvas, 0, 200, windowWidth, 200, paint);
    sk_canvas_draw_line(canvas, 200, 0, 200, windowHeight, paint);

    sk_paint_delete(paint);

    return nilObj;
}

OBJ primOpenWindow(int nargs, OBJ args[]) {
    int w = intOrFloatArg(0, 500, nargs, args);
    int h = intOrFloatArg(1, 500, nargs, args);

    int useHighDPIFlag = ((nargs > 2) && (args[2] == trueObj)) ? 1 : 0;
    char* title = strArg(3, "GP", nargs, args);

    int screenBufferFlag = (nargs > 4) && (trueObj == args[4]);  // use bitmap screen buffer
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
    glfwSwapInterval(1);

    int actualW, logicalW, actualH, logicalH;
    float contentScaleX, contentScaleY;
    glfwGetWindowSize(window, &logicalW, &logicalH);
    glfwGetWindowContentScale(window, &contentScaleX, &contentScaleY);
    actualW = logicalW * contentScaleX;
    actualH = logicalH * contentScaleY;

    windowWidth = actualW;
    windowHeight = actualH;

    context = makeSkiaContext();
    if (!context) {
        fprintf(stderr, "Failed to create Skia context\n");
        exit(EXIT_FAILURE);
    }
    repaintIfNeeded();
    needsRepaint = true;

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
    repaintIfNeeded();
    return getEvent();
}

static sk_color_t kErrorColorMarker = 0xFFFF0000;
static sk_color_t makeColorFromObj(OBJ colorObj, bool ignoreAlpha){
    // Set the color for the next drawing operation.
    // Set the renderer's draw color (for texture drawing)
    // and the globals rgb and alpha (for bitmap drawing).
    int rgb = 0;
    int alpha = 255;
    int words = objWords(colorObj);
    if (words < 3) {
        WARN("could to create a color value");
        return kErrorColorMarker;
    }
    int r = isInt(FIELD(colorObj, 0)) ? obj2int(FIELD(colorObj, 0)) : 0;
    int g = isInt(FIELD(colorObj, 1)) ? obj2int(FIELD(colorObj, 1)) : 0;
    int b = isInt(FIELD(colorObj, 2)) ? obj2int(FIELD(colorObj, 2)) : 0;
    int a = ((words > 3) && isInt(FIELD(colorObj, 3))) ? obj2int(FIELD(colorObj, 3)) : 255;
    r = clip(r, 0, 255);
    g = clip(g, 0, 255);
    b = clip(b, 0, 255);
    a = ignoreAlpha ? 255 : clip(a, 0, 255);
    rgb = (r << 16) | (g << 8) | b;
    alpha = a;

    return (a<<24) | rgb;
}
static sk_rect_t makeRect(int x, int y, int w, int h){
    return (sk_rect_t){.left=x, .top=y, .right=x+w, .bottom= y+h};
}

OBJ primFillRect(int nargs, OBJ args[]) {
    if (nargs < 2) return notEnoughArgsFailure();
    if (!initialized) initGraphics();
    //OBJ _unused = args[0];// textureOrBitmap - unused here

    sk_color_t color = makeColorFromObj(args[1], false);
    sk_rect_t rect = makeRect(intOrFloatArg(2, 0, nargs, args), intOrFloatArg(3, 0, nargs, args),
                              intOrFloatArg(4, 100, nargs, args), intOrFloatArg(5, 100, nargs, args));

    sk_paint_t* paint = sk_paint_new();
    sk_paint_set_style(paint, SK_PAINT_STYLE_FILL);
    sk_paint_set_color(paint, color);
    //printf("Drawing rect color : %x, rect{%f, %f, %f, %f}\n", color, rect.top, rect.left, (rect.right - rect.left), (rect.top-rect.bottom));
    sk_canvas_draw_rect(canvas, &rect, paint);
    sk_paint_delete(paint);
    needsRepaint = true;

    //return primFailed("Forced trap in primFillRect ");
    return nilObj;
}
OBJ primFlipWindowBuffer(int nargs, OBJ args[]) {
    needsRepaint = true;
    repaintIfNeeded();
    //printf("redrawing... \n");
    return nilObj;
}

OBJ primCloseWindow(int nargs, OBJ args[]) { return nilObj; }
OBJ primSetFullScreen(int nargs, OBJ args[]) { return nilObj; }
OBJ primSetWindowTitle(int nargs, OBJ args[]) { return nilObj; }
OBJ primSetCursor(int nargs, OBJ args[]) { return nilObj; }

// ***** Graphics Primitive Lookup *****

PrimEntry graphicsPrimList[] = {
    {"-----", NULL, "Graphics: Skia"},
    {"drawSkiaImage", primSkiaDraw, "Draw the test image using Skia"},
    {"drawRect", primSkiaRect, "Draw rect x,y,w,h,color"},

    {"-----", NULL, "Graphics: Windows"},
    {"openWindow", primOpenWindow, "Open the graphics window. Arguments: [width height tryRetinaFlag title]"},
    {"closeWindow", primCloseWindow, "Close the graphics window."},
    //    {"clearBuffer",        primClearWindowBuffer,        "Clear the offscreen window buffer to a color. Ex. clearBuffer (color 255 0 0); flipBuffer"},
    //    {"showTexture",        primShowTexture,            "Draw the given texture. Draw to window buffer if dstTexture is nil. Arguments: dstTexture srcTexture [x y alpha xScale yScale rotationDegrees flip blendMode clipRect]"},
    {"flipBuffer", primFlipWindowBuffer, "Flip the onscreen and offscreen window buffers to make changes visible."},
    {"windowSize", primWindowSize, "Return an array containing the width and height of the window in logical and physical (high resolution) pixels."},
    {"setFullScreen", primSetFullScreen, "Set full screen mode. Argument: fullScreenFlag"},
    {"setWindowTitle", primSetWindowTitle, "Set the graphics window title to the given string."},
    {"-----", NULL, "Graphics: Textures"},
    //    {"createTexture",    primCreateTexture,            "Create a reference to new texture (a drawing surface in graphics memory). Arguments: width height [fillColor]. Ex. ref = (createTexture 100 100)"},
    //    {"destroyTexture",    primDestroyTexture,            "Destroy a texture reference. Ex. destroyTexture ref"},
    //    {"readTexture",        primReadTexture,            "Copy the given texture into the given bitmap. Arguments: bitmap texture"},
    //    {"updateTexture",    primUpdateTexture,            "Update the given texture from the given bitmap. Arguments: texture bitmap"},
    {"-----", NULL, "Graphics: Drawing"},
    {"fillRect", primFillRect, "Draw a rectangle. Draw to window buffer if textureOrBitmap is nil. Arguments: textureOrBitmap color [x y width height blendMode]."},
    //    {"drawBitmap",        primDrawBitmap,                "Draw a bitmap. Draw to window buffer if textureOrBitmap is nil. Arguments: textureOrBitmap srcBitmap [x y alpha blendMode clipRect]"},
    //    {"warpBitmap",        primWarpBitmap,                "Scaled and/or rotate a bitmap. Arguments: dstBitmap srcBitmap [centerX centerY scaleX scaleY rotation]"},
    //    {"drawLineOnBitmap", primDrawLineOnBitmap,        "Draw a line on a bitmap. Only 1-pixel anti-aliased lines are supported. Arguments: dstBitmap x1 y1 x2 y2 [color lineWidth antiAliasFlag]"},
    {"-----", NULL, "User Input"},
    {"nextEvent", primNextEvent, "Return a dictionary representing the next user input event, or nil if the queue is empty."},
    //    {"getClipboard",    primGetClipboard,            "Return the string from the clipboard, or the empty string if the cliboard is empty."},
    //    {"setClipboard",    primSetClipboard,            "Set the clipboard to the given string."},
    //    {"showKeyboard",    primShowKeyboard,            "Show or hide the on-screen keyboard on a touchsceen devices. Argument: true or false."},
    {"setCursor", primSetCursor, "Change the mouse pointer appearance. Argument: cursorNumber (0 -> arrow, 3 -> crosshair, 11 -> hand...)"},

//    {"closeAudio",        primNoop,        "Close the audio output driver."},

};

PrimEntry* pocPrimitives(int* primCount) {
    *primCount = sizeof(graphicsPrimList) / sizeof(PrimEntry);
    return graphicsPrimList;
}
