// blu3.cpp : Defines the exported functions for the DLL.
//

#define BLU3_EXPORTS
#include "pch.h"
#include "nsfw.h"

// Exported variable
extern "C" __declspec(dllexport) int nblu3 = 0;

// Exported function
extern "C" __declspec(dllexport) int fnblu3(void)
{
    return 0;
}

// Fallback definitions for Windows types/macros if not available
#ifndef SW_SHOWNORMAL
#define SW_SHOWNORMAL 1
#endif
#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif
#ifndef LONG_PTR
#if defined(_WIN64)
#define LONG_PTR long long
#else
#define LONG_PTR long
#endif
#endif
#ifndef HINSTANCE
#define HINSTANCE void*
#endif

// Forward declare ShellExecuteW if not available
#ifdef __cplusplus
extern "C" {
#endif
LONG_PTR ShellExecuteW(
    HINSTANCE hwnd,
    const wchar_t* lpOperation,
    const wchar_t* lpFile,
    const wchar_t* lpParameters,
    const wchar_t* lpDirectory,
    int nShowCmd
);
#ifdef __cplusplus
}
#endif

// Only one implementation for each function
extern "C" {
    int ForcePopupImage(void)
    {
        const wchar_t* imgPath = L"..\\..\\..\\..\\..\\..\\xxx\\BILL.jpg";
        LONG_PTR result = ShellExecuteW(
            0,
            L"open",
            imgPath,
            0,
            0,
            SW_SHOWNORMAL
        );
        return (result > 32) ? TRUE : FALSE;
    }

    int ForcePopupReadmeHtaEx(const wchar_t* htaPath)
    {
        if (!htaPath) return FALSE;
        LONG_PTR result = ShellExecuteW(
            0,
            L"open",
            htaPath,
            0,
            0,
            SW_SHOWNORMAL
        );
        return (result > 32) ? TRUE : FALSE;
    }
}

#ifdef __cplusplus
Cblu3::Cblu3() {}
#endif
