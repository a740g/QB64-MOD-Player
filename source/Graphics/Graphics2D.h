//----------------------------------------------------------------------------------------------------------------------
// Extended graphics routines
// Copyright (c) 2025 Samuel Gomes
//----------------------------------------------------------------------------------------------------------------------

#pragma once

// #define TOOLBOX64_DEBUG 1
#include "../Debug/Debug.h"
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <unordered_map>

#ifndef INC_COMMON_CPP
// This stuff is from QB64-PE common.h and is only here for debugging purposes
struct img_struct {
    void *lock_offset;
    int64_t lock_id;
    uint8_t valid;   // 0,1 0=invalid
    uint8_t text;    // if set, surface is a text surface
    uint8_t console; // dummy surface to absorb unimplemented console functionality
    uint16_t width, height;
    uint8_t bytes_per_pixel;  // 1,2,4
    uint8_t bits_per_pixel;   // 1,2,4,8,16(text),32
    uint32_t mask;            // 1,3,0xF,0xFF,0xFFFF,0xFFFFFFFF
    uint16_t compatible_mode; // 0,1,2,7,8,9,10,11,12,13,32,256
    uint32_t color, background_color, draw_color;
    uint32_t font;               // 8,14,16,?
    int16_t top_row, bottom_row; // VIEW PRINT settings, unique (as in QB) to each "page"
    int16_t cursor_x, cursor_y;  // unique (as in QB) to each "page"
    uint8_t cursor_show, cursor_firstvalue, cursor_lastvalue;

    union {
        uint8_t *offset;
        uint32_t *offset32;
    };

    uint32_t flags;
    uint32_t *pal;
    int32_t transparent_color; //-1 means no color is transparent
    uint8_t alpha_disabled;
    uint8_t holding_cursor;
    uint8_t print_mode;
    // BEGIN apm ('active page migration')
    // everything between apm points is migrated during active page changes
    // note: apm data is only relevant to graphics modes
    uint8_t apm_p1;
    int32_t view_x1, view_y1, view_x2, view_y2;
    int32_t view_offset_x, view_offset_y;
    float x, y;
    uint8_t clipping_or_scaling;
    float scaling_x, scaling_y, scaling_offset_x, scaling_offset_y;
    float window_x1, window_y1, window_x2, window_y2;
    double draw_ta;
    double draw_scale;
    uint8_t apm_p2;
    // END apm
};

// NOTE: These are QB64-PE internal functions and can change at any time!
extern uint8_t image_get_bgra_red(uint32_t c);
extern uint8_t image_get_bgra_green(uint32_t c);
extern uint8_t image_get_bgra_blue(uint32_t c);
extern uint8_t image_get_bgra_alpha(uint32_t c);
extern uint32_t image_get_bgra_bgr(uint32_t c);
extern uint32_t image_set_bgra_alpha(uint32_t c, uint8_t a = 0xFFu);
extern uint32_t image_make_bgra(uint8_t r, uint8_t g, uint8_t b, uint8_t a = 0xFFu);
extern uint32_t image_swap_red_blue(uint32_t clr);
extern uint8_t image_clamp_color_component(int n);
extern uint32_t func__rgb32(int32_t r, int32_t g, int32_t b, int32_t a);
extern uint32_t func__rgb32(int32_t r, int32_t g, int32_t b);
extern uint32_t func__rgb32(int32_t i, int32_t a);
extern uint32_t func__rgb32(int32_t i);
extern uint32_t func__rgba32(int32_t r, int32_t g, int32_t b, int32_t a);
extern int32_t func__alpha32(uint32_t col);
extern int32_t func__red32(uint32_t col);
extern int32_t func__green32(uint32_t col);
extern int32_t func__blue32(uint32_t col);
extern void pset_and_clip(int32_t x, int32_t y, uint32_t color);
extern void fast_boxfill(int32_t x1, int32_t y1, int32_t x2, int32_t y2, uint32_t color);
extern void validatepage(int32_t n);
#endif

// NOTE: These are QB64-PE internal structures and can change at any time!
extern img_struct *read_page;
extern img_struct *write_page;
extern img_struct *img;
extern int32_t *page;
extern int32_t nextimg;
extern uint8_t charset8x8[256][8][8];
extern uint8_t charset8x16[256][16][8];

/// @brief This is a function pointer type that we'll use to plot "pixels" on graphics as well and "text" surfaces.
typedef void (*Graphics_SetPixelFunction_)(int32_t x, int32_t y, uint32_t clrAtr);

/// @brief We'll use this internally so that we do not have the overhead of calling _Graphics_SetSetPixelFunction() for every pixel.
static Graphics_SetPixelFunction_ Graphics_SetPixel_ = nullptr;

/// @brief This is used to plot a text "pixel" on a "text" surface. The pixel is clipped if it is outside bounds.
/// @param x The x position.
/// @param y The y position.
/// @param clrAtr A combination of the ASCII character and the text color attributes.
static inline void Graphics_SetTextPixelClipped_(int32_t x, int32_t y, uint32_t clrAtr) {
    auto width = write_page->width;

    if (x >= 0 and x < width and y >= 0 and y < write_page->height) {
        *(reinterpret_cast<uint16_t *>(write_page->offset) + width * y + x) = (uint16_t)clrAtr;
    }
}

/// @brief This selects the correct "SetPixel" function for later rendering.
static inline void Graphics_SelectSetPixelFunction_() {
    Graphics_SetPixel_ = write_page->text ? Graphics_SetTextPixelClipped_ : pset_and_clip;
}

/// @brief Public library function for plotting pixels on text and graphic surfaces. This will clip out-of-bounds pixels.
/// @param x The x position.
/// @param y The y position.
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color.
inline void Graphics_DrawPixel(int32_t x, int32_t y, uint32_t clrAtr) {
    Graphics_SelectSetPixelFunction_();
    Graphics_SetPixel_(x, y, clrAtr);
}

/// @brief  This gets the pixel at the specified x, y position from the current source image or text surface.
/// @param x The x position.
/// @param y The y position.
/// @return The pixel color.
inline uint32_t Graphics_GetPixel(int32_t x, int32_t y) {
    auto width = read_page->width;

    if (x >= 0 and x < width and y >= 0 and y < read_page->height) {
        if (read_page->text) {
            return *(reinterpret_cast<uint16_t *>(read_page->offset) + width * y + x);
        } else {
            if (read_page->bytes_per_pixel == 1) {
                return read_page->offset[width * y + x] & read_page->mask;
            } else {
                return read_page->offset32[width * y + x];
            }
        }
    }

    return 0;
}

/// @brief Makes a character + text attribute pair for text mode images.
/// @param character An ASCII character.
/// @param fColor The foreground color (0 - 15).
/// @param bColor The background color (0 - 15).
/// @return A 16-bit text + color attribute pair.
inline constexpr uint16_t Graphics_MakeTextColorAttribute(uint8_t character, uint8_t fColor, uint8_t bColor) {
    return (uint16_t)character | ((((bColor > 7) << 7) | (bColor << 4) | (fColor & 0x0F)) << 8);
}

/// @brief Makes a character + text attribute pair for text mode images using the _DEFAULTCOLOR and _BACKGROUNDCOLOR.
/// @param character An ASCII character.
/// @return A 16-bit text + color attribute pair.
inline uint16_t Graphics_MakeDefaultTextColorAttribute(uint8_t character) {
    return (uint16_t)character | ((((write_page->color > 15) << 7) | ((write_page->background_color & 0xFF) << 4) | (write_page->color & 0x0F)) << 8);
}

/// @brief Gets the ASCII character from a text attribute pair.
/// @param clrAttr A 16-bit text + color attribute pair.
/// @return The ASCII character.
inline constexpr uint8_t Graphics_GetTextAttributeCharacter(uint32_t clrAttr) {
    return uint8_t(clrAttr & 0xFF);
}

/// @brief Gets the foreground color from a text attribute pair.
/// @param clrAttr A 16-bit text + color attribute pair.
/// @return The foreground color (0 - 15).
inline constexpr uint8_t Graphics_GetTextAttributeForegroundColor(uint32_t clrAttr) {
    return uint8_t((clrAttr >> 8) & 0x0F);
}

/// @brief Gets the background color from a text attribute pair.
/// @param clrAttr A 16-bit text + color attribute pair.
/// @return The background color (0 - 15).
inline constexpr uint8_t Graphics_GetTextAttributeBackgroundColor(uint32_t clrAttr) {
    auto attr = uint8_t(clrAttr >> 8);
    return ((attr & 0x70) >> 4) | ((attr & 0x80) >> 3);
}

/// @brief Sets the foreground color for the current destination image.
/// @param fColor The foreground color (0 - 15 for text mode).
inline void Graphics_SetForegroundColor(uint32_t fColor) {
    write_page->color = write_page->text ? fColor & 0x0F : fColor;
}

/// @brief Gets the foreground color for the current destination image.
/// @return The foreground color (0 - 15 for text mode).
inline uint32_t Graphics_GetForegroundColor() {
    return write_page->text ? write_page->color & 0x0F : write_page->color;
}

/// @brief Sets the background color for the current destination image.
/// @param bColor The background color (0 - 15 for text mode).
inline void Graphics_SetBackgroundColor(uint32_t bColor) {
    if (write_page->text) {
        write_page->background_color = bColor & 0x07;
        write_page->color = write_page->color | ((bColor > 7) << 4);
    } else {
        write_page->background_color = bColor;
    }
}

/// @brief Gets the background color for the current destination image.
/// @return The background color (0 - 15 for text mode).
inline uint32_t Graphics_GetBackgroundColor() {
    return write_page->text ? (write_page->background_color & 0x07) | ((write_page->color > 15) << 3) : write_page->background_color;
}

/// @brief Draws a horizontal line (works in both text and graphics modes).
/// @param lx Left x position.
/// @param ty Top y position.
/// @param rx Right x position.
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color.
void Graphics_DrawHorizontalLine(int32_t lx, int32_t ty, int32_t rx, uint32_t clrAtr) {
    // Ensure the starting and ending coordinates are ordered correctly
    if (lx > rx) {
        std::swap(lx, rx);
    }

    // Ensure ty is within the image height
    if (ty < 0 || ty >= write_page->height || lx >= write_page->width || rx < 0) {
        return; // Line is completely outside the image
    }

    // Clip the line to the image boundaries
    if (lx < 0) {
        lx = 0;
    }
    if (rx >= write_page->width) {
        rx = write_page->width - 1;
    }

    TOOLBOX64_DEBUG_PRINT("Drawing horizontal line segment: (%i, %i) - (%i, %i)", lx, ty, rx, ty);

    if (write_page->text) {
        // Get pointer to the starting "pixel"
        auto buffer = (reinterpret_cast<uint16_t *>(write_page->offset) + write_page->width * ty + lx);

        // Draw the complete line
        std::fill(buffer, buffer + (1 + rx - lx), clrAtr);
    } else {
        // Use a different method for non-text mode
        fast_boxfill(lx, ty, rx, ty, clrAtr);
    }
}

/// @brief Draws a vertical line (works in both text and graphics modes).
/// @param lx Left x position.
/// @param ty Top y position.
/// @param by Bottom y position.
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color.
void Graphics_DrawVerticalLine(int32_t lx, int32_t ty, int32_t by, uint32_t clrAtr) {
    // Ensure the starting and ending coordinates are ordered correctly
    if (ty > by) {
        std::swap(ty, by);
    }

    // Ensure lx is within the image width
    if (lx < 0 || lx >= write_page->width || ty >= write_page->height || by < 0) {
        return; // Line is completely outside the image
    }

    // Clip the line to the image boundaries
    if (ty < 0) {
        ty = 0;
    }
    if (by >= write_page->height) {
        by = write_page->height - 1;
    }

    TOOLBOX64_DEBUG_PRINT("Drawing vertical line segment: (%i, %i) - (%i, %i)", lx, ty, lx, by);

    if (write_page->text) {
        // Get pointer to the starting "pixel"
        auto buffer = (reinterpret_cast<uint16_t *>(write_page->offset) + write_page->width * ty + lx);

        // Draw the "pixels" and then step by image width to get to the next pixel
        for (auto y = ty; y <= by; y++) {
            *buffer = clrAtr;
            buffer += write_page->width;
        }
    } else {
        // Use a different method for non-text mode
        fast_boxfill(lx, ty, lx, by, clrAtr);
    }
}

/// @brief Draws a rectangle (works in both text and graphics modes).
/// @param lx Left x position.
/// @param ty Top y position.
/// @param rx Right x position.
/// @param by Bottom y position.
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color.
void Graphics_DrawRectangle(int32_t lx, int32_t ty, int32_t rx, int32_t by, uint32_t clrAtr) {
    // Ensure the starting and ending coordinates are ordered correctly
    if (ty > by) {
        std::swap(ty, by);
    }
    if (lx > rx) {
        std::swap(lx, rx);
    }

    TOOLBOX64_DEBUG_PRINT("Drawing rectangle: (%i, %i) - (%i, %i)", lx, ty, rx, by);

    // Draw the top and bottom sides
    Graphics_DrawHorizontalLine(lx, ty, rx, clrAtr);
    Graphics_DrawHorizontalLine(lx, by, rx, clrAtr);

    // Avoid re-drawing corners
    ++ty;
    --by;

    // Draw the left and right sides
    if (by >= ty) {
        Graphics_DrawVerticalLine(lx, ty, by, clrAtr);
        Graphics_DrawVerticalLine(rx, ty, by, clrAtr);
    }
}

/// @brief Draws a filled rectangle (works in both text and graphics modes).
/// @param lx Left x position.
/// @param ty Top y position.
/// @param rx Right x position.
/// @param by Bottom y position.
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color.
void Graphics_DrawFilledRectangle(int32_t lx, int32_t ty, int32_t rx, int32_t by, uint32_t clrAtr) {
    // Ensure the starting and ending coordinates are ordered correctly
    if (lx > rx) {
        std::swap(lx, rx);
    }
    if (ty > by) {
        std::swap(ty, by);
    }

    // Leave if rectangle is completely outside the image
    if (lx >= write_page->width || ty >= write_page->height || rx < 0 || by < 0) {
        return;
    }

    // Clip rectangle to image
    if (lx < 0) {
        lx = 0;
    }
    if (rx >= write_page->width) {
        rx = write_page->width - 1;
    }
    if (ty < 0) {
        ty = 0;
    }
    if (by >= write_page->height) {
        by = write_page->height - 1;
    }

    TOOLBOX64_DEBUG_PRINT("Drawing filled rectangle: (%i, %i) - (%i, %i)", lx, ty, rx, ty);

    if (write_page->text) {
        // Get pointer to the starting "pixel"
        auto buffer = (reinterpret_cast<uint16_t *>(write_page->offset) + write_page->width * ty + lx);

        // Draw one complete line
        auto rectWidth = 1 + rx - lx;
        std::fill(buffer, buffer + rectWidth, clrAtr);

        // Copy the remaining lines
        rectWidth <<= 1;                        // Since we are dealing with 2 byte attributes
        auto dest = buffer + write_page->width; // Get the pointer to the next line
        for (auto y = ty; y < by; y++)          // "y < by" since we already rendered the first line using std::fill
        {
            memcpy(dest, buffer, rectWidth); // Copy the first line
            dest += write_page->width;       // Move to the next line
        }
    } else {
        // Use a different method for non-text mode
        fast_boxfill(lx, ty, rx, by, clrAtr);
    }
}

/// @brief This is an internal line drawing routine. This does not draw the last pixel and hence can be used to make multi-line shapes.
/// @param x1 Starting position x.
/// @param y1 Starting position y.
/// @param x2 Ending position x.
/// @param y2 Ending position y.
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color.
static inline void Graphics_DrawLineInternal_(int32_t x1, int32_t y1, int32_t x2, int32_t y2, uint32_t clrAtr) {
    bool isVerticalLonger = false;
    int32_t shortDistance = y2 - y1;
    int32_t longDistance = x2 - x1;

    if (abs(shortDistance) > abs(longDistance)) {
        std::swap(shortDistance, longDistance);
        isVerticalLonger = true;
    }

    int32_t increment, endDistance = longDistance;

    if (longDistance < 0) {
        increment = -1;
        longDistance = -longDistance;
    } else {
        increment = 1;
    }

    int32_t deltaIncrement;

    if (longDistance == 0) {
        deltaIncrement = 0;
    } else {
        deltaIncrement = (shortDistance << 16) / longDistance;
    }

    int32_t j = 0;

    if (isVerticalLonger) {
        for (int32_t i = 0; i != endDistance; i += increment) {
            Graphics_SetPixel_(x1 + (j >> 16), y1 + i, clrAtr);
            j += deltaIncrement;
        }
    } else {
        for (int32_t i = 0; i != endDistance; i += increment) {
            Graphics_SetPixel_(x1 + i, y1 + (j >> 16), clrAtr);
            j += deltaIncrement;
        }
    }
}

/// @brief Draws a line from x1, y1 to x2, y2 (works in both text and graphics modes).
/// @param x1 Starting position x.
/// @param y1 Starting position y.
/// @param x2 Ending position x.
/// @param y2 Ending position y.
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color.
void Graphics_DrawLine(int32_t x1, int32_t y1, int32_t x2, int32_t y2, uint32_t clrAtr) {
    // TODO: See https://lodev.org/cgtutor/lineclipping.html
    // Check if both endpoints of the line are outside the image bounds
    if ((x1 < 0 && x2 < 0) || (x1 >= write_page->width && x2 >= write_page->width) || (y1 < 0 && y2 < 0) ||
        (y1 >= write_page->height && y2 >= write_page->height)) {
        return; // Line is completely outside the image
    }

    // Select the correct pixel drawing routine just once
    Graphics_SelectSetPixelFunction_();

    // Call the internal line-drawing routine. This will use whatever pixel drawing routine was selected
    Graphics_DrawLineInternal_(x1, y1, x2, y2, clrAtr);

    // Plot the ending pixel
    Graphics_SetPixel_(x2, y2, clrAtr);
}

/// @brief Draws a circle (works in both text and graphics modes).
/// @param x The circles center x position.
/// @param y The circles center y position.
/// @param radius The radius of the circle.
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color.
void Graphics_DrawCircle(int32_t x, int32_t y, int32_t radius, uint32_t clrAtr) {
    // Clip the circle completely if bounding box is completely off-image
    if (x + radius < 0 || x - radius >= write_page->width || y + radius < 0 || y - radius >= write_page->height) {
        return;
    }

    Graphics_SelectSetPixelFunction_();

    // Special case: draw a single pixel if the radius is <= zero
    if (radius <= 0) {
        Graphics_SetPixel_(x, y, clrAtr);
        return;
    }

    int32_t p = 1 - radius, cx = 0, cy = radius, px, py;

    do {
        // Calculate the eight symmetric points and set the pixels
        px = x + cx;
        py = y + cy;
        Graphics_SetPixel_(px, py, clrAtr);
        px = x - cx;
        Graphics_SetPixel_(px, py, clrAtr);
        px = x + cx;
        py = y - cy;
        Graphics_SetPixel_(px, py, clrAtr);
        px = x - cx;
        Graphics_SetPixel_(px, py, clrAtr);
        px = x + cy;
        py = y + cx;
        Graphics_SetPixel_(px, py, clrAtr);
        py = y - cx;
        Graphics_SetPixel_(px, py, clrAtr);
        px = x - cy;
        py = y + cx;
        Graphics_SetPixel_(px, py, clrAtr);
        py = y - cx;
        Graphics_SetPixel_(px, py, clrAtr);

        ++cx;

        if (p < 0) {
            p += ((cx << 1) + 1);
        } else {
            cy--;
            p += (((cx - cy) << 1) + 1);
        }
    } while (cx <= cy);
}

/// @brief Draws a filled circle (works in both text and graphics modes)
/// @param x The circles center x position
/// @param y The circles center y position
/// @param radius The radius of the circle
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawFilledCircle(int32_t x, int32_t y, int32_t radius, uint32_t clrAtr) {
    // Clip the circle completely if bounding box is completely off-image
    if (x + radius < 0 || x - radius >= write_page->width || y + radius < 0 || y - radius >= write_page->height) {
        return;
    }

    // Special case: draw a single pixel if the radius is < zero
    if (radius <= 0) {
        Graphics_DrawPixel(x, y, clrAtr);
        return;
    }

    // Initialize the coordinates and error term
    auto px = radius, py = 0, radiusError = -radius;

    // Draw the central horizontal line
    Graphics_DrawFilledRectangle(x - px, y, x + px, y, clrAtr);

    while (px > py) {
        // Update the error term
        radiusError += (py << 1) + 1;

        if (radiusError >= 0) {
            if (px != py + 1) {
                // Draw horizontal lines at the top and bottom of the circle
                Graphics_DrawFilledRectangle(x - py, y - px, x + py, y - px, clrAtr);
                Graphics_DrawFilledRectangle(x - py, y + px, x + py, y + px, clrAtr);
            }
            // Decrease the x coordinate and update the error term
            --px;
            radiusError -= px << 1;
        }

        // Increase the y coordinate
        ++py;

        // Draw horizontal lines at the top and bottom of the circle
        Graphics_DrawFilledRectangle(x - px, y - py, x + px, y - py, clrAtr);
        Graphics_DrawFilledRectangle(x - px, y + py, x + px, y + py, clrAtr);
    }
}

/// @brief Draws an ellipse (works in both text and graphics modes)
/// @param x The circles center x position
/// @param y The circles center y position
/// @param rx The horizontal radius
/// @param ry The vertical radius
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawEllipse(int32_t x, int32_t y, int32_t rx, int32_t ry, uint32_t clrAtr) {
    // Calculate the bounding box
    auto left = x - rx;
    auto right = x + rx;
    auto top = y - ry;
    auto bottom = y + ry;

    // Clip the ellipse completely if bounding box is completely off-image
    if (right < 0 || left >= write_page->width || bottom < 0 || top >= write_page->height)
        return;

    Graphics_SelectSetPixelFunction_();

    // Special case: draw a single pixel if both rx and ry are <= zero
    if (rx <= 0 && ry <= 0) {
        Graphics_SetPixel_(x, y, clrAtr);
        return;
    }

    // Special case for rx = 0: draw a vline
    if (rx == 0) {
        Graphics_DrawVerticalLine(x, top, bottom, clrAtr);
        return;
    }

    // Special case for ry = 0: draw a hline
    if (ry == 0) {
        Graphics_DrawHorizontalLine(left, y, right, clrAtr);
        return;
    }

    int32_t ix, iy;
    int32_t h, i, j, k;
    h = i = j = k = 0xFFFF;

    if (rx > ry) {
        ix = 0;
        iy = rx << 6;

        do {
            int32_t oh = h;
            int32_t oi = i;
            int32_t oj = j;
            int32_t ok = k;

            h = (ix + 32) >> 6;
            i = (iy + 32) >> 6;
            j = (h * ry) / rx;
            k = (i * ry) / rx;

            if ((h != oh || k != ok) && (h < oi)) {
                Graphics_SetPixel_(x + h, y + k, clrAtr);
                Graphics_SetPixel_(x - h, y + k, clrAtr);
                Graphics_SetPixel_(x + h, y - k, clrAtr);
                Graphics_SetPixel_(x - h, y - k, clrAtr);
            }

            if ((i != oi || j != oj) && (h < i)) {
                Graphics_SetPixel_(x + i, y + j, clrAtr);
                Graphics_SetPixel_(x - i, y + j, clrAtr);
                Graphics_SetPixel_(x + i, y - j, clrAtr);
                Graphics_SetPixel_(x - i, y - j, clrAtr);
            }

            ix = ix + (iy / rx);
            iy = iy - (ix / rx);
        } while (i > h);
    } else {
        ix = 0;
        iy = ry << 6;

        do {
            int32_t oh = h;
            int32_t oi = i;
            int32_t oj = j;
            int32_t ok = k;

            h = (ix + 32) >> 6;
            i = (iy + 32) >> 6;
            j = (h * rx) / ry;
            k = (i * rx) / ry;

            if ((j != oj || i != oi) && (h < i)) {
                Graphics_SetPixel_(x + j, y + i, clrAtr);
                Graphics_SetPixel_(x - j, y + i, clrAtr);
                Graphics_SetPixel_(x + j, y - i, clrAtr);
                Graphics_SetPixel_(x - j, y - i, clrAtr);
            }

            if ((k != ok || h != oh) && (h < oi)) {
                Graphics_SetPixel_(x + k, y + h, clrAtr);
                Graphics_SetPixel_(x - k, y + h, clrAtr);
                Graphics_SetPixel_(x + k, y - h, clrAtr);
                Graphics_SetPixel_(x - k, y - h, clrAtr);
            }

            ix = ix + (iy / ry);
            iy = iy - (ix / ry);
        } while (i > h);
    }
}

/// @brief Draws a filled ellipse (works in both text and graphics modes)
/// @param cx The circles center x position
/// @param cy The circles center y position
/// @param rx The horizontal radius
/// @param ry The vertical radius
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawFilledEllipse(int32_t cx, int32_t cy, int32_t rx, int32_t ry, uint32_t clrAtr) {
    // Calculate the bounding box
    auto left = cx - rx;
    auto right = cx + rx;
    auto top = cy - ry;
    auto bottom = cy + ry;

    // Clip the ellipse completely if bounding box is outside the image bounds
    if (right < 0 || left >= write_page->width || bottom < 0 || top >= write_page->height)
        return;

    // Special case if both rx and ry are <= zero: draw a single pixel
    if (rx <= 0 && ry <= 0) {
        Graphics_DrawPixel(cx, cy, clrAtr);
        return;
    }

    // Special case for rx = 0: draw a vline
    if (rx == 0) {
        Graphics_DrawVerticalLine(cx, top, bottom, clrAtr);
        return;
    }

    // Special case for ry = 0: draw a hline
    if (ry == 0) {
        Graphics_DrawHorizontalLine(left, cy, right, clrAtr);
        return;
    }

    int32_t a = 2 * rx * rx;
    int32_t b = 2 * ry * ry;
    int32_t x = rx;
    int32_t y = 0;
    int32_t xx = ry * ry * (1 - rx - rx);
    int32_t yy = rx * rx;
    int32_t sx = b * rx;
    int32_t sy = 0;
    int32_t e = 0;

    while (sx >= sy) {
        Graphics_DrawHorizontalLine(cx - x, cy - y, cx + x, clrAtr);
        if (y != 0)
            Graphics_DrawHorizontalLine(cx - x, cy + y, cx + x, clrAtr);

        y = y + 1;
        sy = sy + a;
        e = e + yy;
        yy = yy + a;

        if ((e + e + xx) > 0) {
            x = x - 1;
            sx = sx - b;
            e = e + xx;
            xx = xx + b;
        }
    }

    x = 0;
    y = ry;
    xx = rx * ry;
    yy = rx * rx * (1 - ry - ry);
    e = 0;
    sx = 0;
    sy = a * ry;

    while (sx <= sy) {
        Graphics_DrawHorizontalLine(cx - x, cy - y, cx + x, clrAtr);
        Graphics_DrawHorizontalLine(cx - x, cy + y, cx + x, clrAtr);

        do {
            x = x + 1;
            sx = sx + b;
            e = e + xx;
            xx = xx + b;
        } while ((e + e + yy) <= 0);

        y = y - 1;
        sy = sy - a;
        e = e + yy;
        yy = yy + a;
    }
}

/// @brief Draws a triangle outline (works in both text and graphics modes)
/// @param x1 Vertex 1 x
/// @param y1 Vertex 1 y
/// @param x2 Vertex 2 x
/// @param y2 Vertex 2 y
/// @param x3 Vertex 3 x
/// @param y3 Vertex 3 y
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawTriangle(int32_t x1, int32_t y1, int32_t x2, int32_t y2, int32_t x3, int32_t y3, uint32_t clrAtr) {
    // Sort vertices by their y-coordinates
    if (y1 > y2) {
        std::swap(x1, x2);
        std::swap(y1, y2);
    }
    if (y1 > y3) {
        std::swap(x1, x3);
        std::swap(y1, y3);
    }
    if (y2 > y3) {
        std::swap(x2, x3);
        std::swap(y2, y3);
    }

    // Check if the entire triangle is outside the image bounds
    if (x3 < 0 || x1 >= write_page->width || y3 < 0 || y1 >= write_page->height)
        return; // The triangle is completely outside the image

    // Select the correct pixel drawing routine just once
    Graphics_SelectSetPixelFunction_();

    // Now draw the 3 sides. Since we are using the internal line drawing function, this will not re-draw the vertices
    Graphics_DrawLineInternal_(x1, y1, x2, y2, clrAtr);
    Graphics_DrawLineInternal_(x2, y2, x3, y3, clrAtr);
    Graphics_DrawLineInternal_(x3, y3, x1, y1, clrAtr);
}

/// @brief Draws a filled triangle (works in both text and graphics modes)
/// @param x1 Vertex 1 x
/// @param y1 Vertex 1 y
/// @param x2 Vertex 2 x
/// @param y2 Vertex 2 y
/// @param x3 Vertex 3 x
/// @param y3 Vertex 3 y
/// @param clrAtr A color index for index graphics surfaces or a text color attribute for text surfaces or a 32-bit RGBA color
void Graphics_DrawFilledTriangle(int32_t x1, int32_t y1, int32_t x2, int32_t y2, int32_t x3, int32_t y3, uint32_t clrAtr) {
    // Sort vertices by their y-coordinates
    if (y1 > y2) {
        std::swap(x1, x2);
        std::swap(y1, y2);
    }
    if (y1 > y3) {
        std::swap(x1, x3);
        std::swap(y1, y3);
    }
    if (y2 > y3) {
        std::swap(x2, x3);
        std::swap(y2, y3);
    }

    // Check if the entire triangle is outside the image bounds
    if (x3 < 0 || x1 >= write_page->width || y3 < 0 || y1 >= write_page->height) {
        return; // The triangle is completely outside the image
    }

    // Calculate slopes of the two lines
    float invSlope1 = (float)(x2 - x1) / (y2 - y1);
    float invSlope2 = (float)(x3 - x1) / (y3 - y1);

    float curX1 = x1;
    float curX2 = x1;

    // Fill the top part of the triangle
    for (int32_t scanlineY = y1; scanlineY <= y2; scanlineY++) {
        Graphics_DrawHorizontalLine(curX1, scanlineY, curX2, clrAtr);
        curX1 += invSlope1;
        curX2 += invSlope2;
    }

    // Calculate the new slope for the bottom part of the clipped triangle
    invSlope1 = (float)(x3 - x2) / (y3 - y2);
    curX1 = x2;

    // Fill the bottom part of the triangle
    for (int32_t scanlineY = y2 + 1; scanlineY <= y3; scanlineY++) {
        Graphics_DrawHorizontalLine(curX1, scanlineY, curX2, clrAtr);
        curX1 += invSlope1;
        curX2 += invSlope2;
    }
}

/// @brief This simply casts a BGRAType to a 32-bit BGRA color.
/// @param bgra A pointer to a 32-bit BGRAType.
/// @return A 32-bit BGRA color.
inline uint32_t Graphics_BGRATypeToBGRA(void *bgra) {
    return (*reinterpret_cast<uint32_t *>(bgra));
}

/// @brief Makes a RGBA color from RGBA components
/// @param r Red (0 - 255)
/// @param g Green (0 - 255)
/// @param b Blue (0 - 255)
/// @param a Alpha (0 - 255)
/// @return Returns an RGBA color
inline constexpr uint32_t Graphics_MakeRGBA(uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    return ((static_cast<uint32_t>(a) << 24) | (static_cast<uint32_t>(b) << 16) | (static_cast<uint32_t>(g) << 8) | static_cast<uint32_t>(r));
}

/// @brief Returns the Red component
/// @param rgba An RGBA color
/// @return Red
inline constexpr uint8_t Graphics_GetRedFromRGBA(uint32_t rgba) {
    return static_cast<uint8_t>(rgba);
}

/// @brief Returns the Green component
/// @param rgba An RGBA color
/// @return Green
inline constexpr uint8_t Graphics_GetGreenFromRGBA(uint32_t rgba) {
    return static_cast<uint8_t>(rgba >> 8);
}

/// @brief Returns the Blue component
/// @param rgba An RGBA color
/// @return Blue
inline constexpr uint8_t Graphics_GetBlueFromRGBA(uint32_t rgba) {
    return static_cast<uint8_t>(rgba >> 16);
}

/// @brief Returns the Alpha value.
/// @param rgba An RGBA color.
/// @return Alpha.
inline constexpr uint8_t Graphics_GetAlphaFromRGBA(uint32_t rgba) {
    return static_cast<uint8_t>(rgba >> 24);
}

/// @brief Interpolates between two colors.
/// @param colorA The first color.
/// @param colorB The second color.
/// @param factor The interpolation factor.
/// @return The interpolated color.
inline constexpr auto Graphics_InterpolateColor(uint32_t colorA, uint32_t colorB, float factor) {
    auto a = func__alpha32(colorA);
    auto r = func__red32(colorA);
    auto g = func__green32(colorA);
    auto b = func__blue32(colorA);

    return func__rgba32(r + int32_t((func__red32(colorB) - r) * factor), g + int32_t((func__green32(colorB) - g) * factor),
                        b + int32_t((func__blue32(colorB) - b) * factor), a + int32_t((func__alpha32(colorB) - a) * factor));
}

/// @brief Calculates the distance between two colors.
/// @param colorA The first color.
/// @param colorB The second color.
/// @return The distance between the two colors.
inline float Graphics_GetRGBDistance(uint32_t colorA, uint32_t colorB) {
    // FIXME: The function name is incorrect
    auto dr = float(image_get_bgra_red(colorA)) - float(image_get_bgra_red(colorB));
    auto dg = float(image_get_bgra_green(colorA)) - float(image_get_bgra_green(colorB));
    auto db = float(image_get_bgra_blue(colorA)) - float(image_get_bgra_blue(colorB));
    return std::sqrt(dr * dr + dg * dg + db * db);
}

/// @brief Calculates the delta between two colors.
/// @param colorA The first color.
/// @param colorB The second color.
/// @return The delta between the two colors.
inline uint32_t Graphics_GetRGBDelta(uint32_t colorA, uint32_t colorB) {
    // FIXME: The function name is incorrect
    auto dr = int32_t(image_get_bgra_red(colorA)) - int32_t(image_get_bgra_red(colorB));
    auto dg = int32_t(image_get_bgra_green(colorA)) - int32_t(image_get_bgra_green(colorB));
    auto db = int32_t(image_get_bgra_blue(colorA)) - int32_t(image_get_bgra_blue(colorB));
    return dr * dr + dg * dg + db * db;
}

/// @brief Finds the closest color index in the palette.
/// @param c The 32-bit color to find.
/// @param palette The palette to search (an array of 32-bit colors).
/// @param paletteColors The number of colors in the palette.
/// @return The index of the closest color in the palette (zero based).
uint32_t Graphics_FindClosestColor(uint32_t c, const uint32_t *palette, uint32_t paletteColors) {
    // FIXME: We can allow custom distance functions
    auto minDistance = std::numeric_limits<uint32_t>::max();
    auto closestIndex = 0u;

    for (auto i = 0u; i < paletteColors; i++) {
        auto c2 = *palette++;
        auto distance = Graphics_GetRGBDelta(c, c2);

        if (distance < minDistance) {
            if (!distance)
                return i; // perfect match

            minDistance = distance;
            closestIndex = i;
        }
    }

    return closestIndex;
}

/// @brief Finds the closest color index in the palette.
/// @param r The red color component.
/// @param g The green color component.
/// @param b The blue color component.
/// @param palette The palette to search (an array of 32-bit colors).
/// @param paletteColors The number of colors in the palette.
/// @return The index of the closest color in the palette (zero based).
inline uint32_t Graphics_FindClosestColor(uint8_t r, uint8_t g, uint8_t b, const uint32_t *palette, uint32_t paletteColors) {
    return Graphics_FindClosestColor(Graphics_MakeRGBA(r, g, b, 0xFFu), palette, paletteColors);
}

/// @brief Renders ASCII art of an image to a destination text mode image.
/// @param src The source graphics image.
/// @param dst The destination text mode image.
void Graphics_RenderASCIIArt(int32_t src, int32_t dst) {
    // TODO: Generate this from the selected font
    // 8-bit intensity gradient
    const static uint8_t intensityGradient[] = {
        0x20, 0xFF, 0x00, 0xFA, 0xF9, 0x2E, 0x27, 0x2C, 0x60, 0x2D, 0xC4, 0x3A, 0x5F, 0x3B, 0xAA, 0x7E, 0xA9, 0xBF, 0xDA, 0x07, 0x22, 0xAD, 0x3D, 0x5E,
        0x7C, 0xC0, 0xD9, 0xFD, 0x2F, 0x1C, 0x5C, 0xF8, 0x3E, 0x2B, 0x29, 0x28, 0xF6, 0x3C, 0xC2, 0x69, 0x1A, 0x1B, 0xCD, 0x8D, 0xBE, 0xB3, 0xB0, 0xC1,
        0xF2, 0x3F, 0xF3, 0xA8, 0xD4, 0x21, 0xA1, 0xFE, 0x7D, 0x87, 0x6C, 0x8B, 0x74, 0x7B, 0xD6, 0xB8, 0x16, 0x49, 0x76, 0x73, 0x63, 0x5B, 0xE7, 0x5D,
        0xF0, 0xD5, 0xE2, 0xB4, 0x78, 0xA2, 0x95, 0xA7, 0xEE, 0xC3, 0x31, 0xB7, 0x25, 0x6F, 0x1D, 0x65, 0xD2, 0x6A, 0xFC, 0x94, 0x09, 0xF1, 0xF7, 0x7A,
        0x72, 0x19, 0x18, 0xCF, 0x37, 0xAF, 0xAE, 0x61, 0x97, 0x6E, 0x75, 0xE5, 0xC8, 0x66, 0xA3, 0xF4, 0xF5, 0x81, 0xB5, 0x8F, 0x8C, 0x54, 0x24, 0xC6,
        0xD3, 0xA4, 0xD1, 0xC5, 0x4A, 0x43, 0xBC, 0xA6, 0x8A, 0xE0, 0xBD, 0xCA, 0x90, 0x33, 0x82, 0x7F, 0x9F, 0xA0, 0x59, 0x9B, 0x98, 0x99, 0x9A, 0xEC,
        0x4C, 0x2A, 0xD0, 0x39, 0xEB, 0x36, 0x13, 0x71, 0x93, 0x79, 0x89, 0x85, 0x70, 0x64, 0x67, 0x11, 0x53, 0xE6, 0x62, 0x86, 0x35, 0xC9, 0x10, 0x32,
        0x04, 0x84, 0x4F, 0x80, 0xE4, 0x47, 0x46, 0xE1, 0xFB, 0x56, 0x96, 0x58, 0x6B, 0x91, 0xBB, 0x9C, 0x68, 0x77, 0xE3, 0x50, 0xCB, 0x6D, 0x34, 0x38,
        0x41, 0x51, 0x1E, 0x1F, 0x12, 0xEF, 0xD8, 0xEA, 0xE9, 0x26, 0x0D, 0x0C, 0x06, 0x88, 0x48, 0x45, 0x4B, 0x9D, 0xA5, 0x5A, 0x55, 0x44, 0x8E, 0x83,
        0x15, 0xDF, 0xED, 0xB1, 0x52, 0xE8, 0xDE, 0xBA, 0xCC, 0x01, 0xDD, 0xDC, 0x42, 0x40, 0xC7, 0x92, 0x0B, 0x57, 0xAB, 0x17, 0xCE, 0x23, 0xB9, 0x4E,
        0xB6, 0x03, 0xD7, 0x30, 0x0F, 0xAC, 0x4D, 0x14, 0x05, 0x9E, 0x0E, 0x0A, 0xB2, 0x02, 0x08, 0xDB};

    // Color -> Character + Attribute hash table
    static std::unordered_map<uint32_t, uint16_t> g_ColorMap;

    // The current destination image handle. We save this to clear the hash table when the destination image changes
    static int32_t g_DestinationImage = 0;

    img_struct *srcImage;

    // Validate source image handle
    if (src >= 0) {
        validatepage(src);
        srcImage = &img[page[src]];
    } else {
        src = -src;
        if (src >= nextimg) {
            error(QB_ERROR_INVALID_HANDLE);
            return;
        }
        srcImage = &img[src];
        if (!srcImage->valid) {
            error(QB_ERROR_INVALID_HANDLE);
            return;
        }
    }

    // Ensure source is a graphics image handle
    if (srcImage->text) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    img_struct *dstImage;

    // Validate destination image handle
    if (dst >= 0) {
        validatepage(dst);
        dstImage = &img[page[dst]];
    } else {
        dst = -dst;
        if (dst >= nextimg) {
            error(QB_ERROR_INVALID_HANDLE);
            return;
        }
        dstImage = &img[dst];
        if (!dstImage->valid) {
            error(QB_ERROR_INVALID_HANDLE);
            return;
        }
    }

    // Ensure destination is a text mode handle and is the same size
    if (!dstImage->text or srcImage->width != dstImage->width or srcImage->height != dstImage->height) {
        error(QB_ERROR_ILLEGAL_FUNCTION_CALL);
        return;
    }

    // Clear the color map only if the destination image has changed
    if (dst != g_DestinationImage) {
        // Clear the color map
        g_ColorMap.clear();

        g_DestinationImage = dst;
    }

    auto dstData = reinterpret_cast<uint16_t *>(dstImage->offset); // destination data
    size_t srcSize = srcImage->width * srcImage->height;
    uint32_t colors = dstImage->text ? 16 : dstImage->mask + 1;

    if (srcImage->bits_per_pixel == 32) {
        // 32bpp source
        auto srcData = srcImage->offset32;

        for (size_t i = 0; i < srcSize; i++) {
            // Check if the src color exists in the color table
            if (g_ColorMap.count(*srcData) == 0) {
                auto r = func__red32(*srcData);
                auto g = func__green32(*srcData);
                auto b = func__blue32(*srcData);
                auto c = Graphics_FindClosestColor(r, g, b, dstImage->pal, colors);

                // Make the character + attribute pair using the nearest color and intensity
                *dstData = (uint16_t)intensityGradient[(r + g + b) * (sizeof(intensityGradient) - 1) / 765] | (uint16_t)(c & 0x0F) << 8;

                // Add the color to the table
                g_ColorMap[*srcData] = *dstData;
            } else {
                // Simply copy the character + attribute pair from the color table
                *dstData = g_ColorMap[*srcData];
            }

            ++dstData;
            ++srcData;
        }
    } else {
        // 8bpp, 4bpp, 2bpp source
        auto srcData = srcImage->offset;

        for (size_t i = 0; i < srcSize; i++) {
            // Check if the src color exists in the color table
            if (g_ColorMap.count(*srcData) == 0) {
                auto r = func__red32(srcImage->pal[*srcData]);
                auto g = func__green32(srcImage->pal[*srcData]);
                auto b = func__blue32(srcImage->pal[*srcData]);
                auto c = Graphics_FindClosestColor(r, g, b, dstImage->pal, colors);

                // Make the character + attribute pair using the nearest color and intensity
                *dstData = (uint16_t)intensityGradient[(r + g + b) * (sizeof(intensityGradient) - 1) / 765] | (uint16_t)(c & 0x0F) << 8;

                // Add the color to the table
                g_ColorMap[*srcData] = *dstData;
            } else {
                // Simply copy the character + attribute pair from the color table
                *dstData = g_ColorMap[*srcData];
            }

            ++dstData;
            ++srcData;
        }
    }
}
