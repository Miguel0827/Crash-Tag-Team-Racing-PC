// The two programs of the package, both run tools\Launcher.ps1 (next to them) with Windows PowerShell, without a console window:
//   Crash Tag Team Racing PC.exe          (-DPLAY) starts the game with the saved settings; the first time, the settings window
//   Crash Tag Team Racing PC - Config.exe          the settings window: installing from the player's ISO, changing settings
// Build: clang -O2 -municode -mwindows [-DPLAY] starter.c starter.res -o "<name>.exe"
#include <windows.h>
#include <wchar.h>

int WINAPI wWinMain(HINSTANCE inst, HINSTANCE prev, PWSTR cmd, int show) {
    (void)inst; (void)prev; (void)cmd; (void)show;
    wchar_t dir[MAX_PATH];
    DWORD n = GetModuleFileNameW(NULL, dir, MAX_PATH);
    if (n == 0 || n >= MAX_PATH) return 1;
    wchar_t *slash = wcsrchr(dir, L'\\');
    if (slash) *slash = 0;

    wchar_t script[MAX_PATH + 32];
    swprintf(script, MAX_PATH + 32, L"%ls\\tools\\Launcher.ps1", dir);
    // run from tools\starter (where the game .exe waits until a game is installed): the package folder is two levels up
    size_t len = wcslen(dir);
    if (GetFileAttributesW(script) == INVALID_FILE_ATTRIBUTES && len > 14 && _wcsicmp(dir + len - 14, L"\\tools\\starter") == 0) {
        dir[len - 14] = 0;
        swprintf(script, MAX_PATH + 32, L"%ls\\tools\\Launcher.ps1", dir);
    }
    if (GetFileAttributesW(script) == INVALID_FILE_ATTRIBUTES) {
        MessageBoxW(NULL, L"tools\\Launcher.ps1 is missing. Extract the whole download (all folders) and run this program from there.\n\n"
                          L"Falta tools\\Launcher.ps1. Descomprime toda la descarga (con sus carpetas) y abre este programa desde ahí.",
                    L"Crash Tag Team Racing PC", MB_ICONERROR);
        return 1;
    }

    wchar_t ps[MAX_PATH];
    UINT m = GetSystemDirectoryW(ps, MAX_PATH);
    if (m == 0 || m >= MAX_PATH - 40) return 1;
    wcscat(ps, L"\\WindowsPowerShell\\v1.0\\powershell.exe");

    wchar_t line[2 * MAX_PATH + 128];
#ifdef PLAY  // the game .exe: straight into the game (the launcher shows its window only when nothing is installed yet)
    swprintf(line, 2 * MAX_PATH + 128, L"\"%ls\" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%ls\" -Play", ps, script);
#else       // the settings .exe: installing a disc and changing settings
    swprintf(line, 2 * MAX_PATH + 128, L"\"%ls\" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%ls\"", ps, script);
#endif

    STARTUPINFOW si = {0};
    si.cb = sizeof si;
    PROCESS_INFORMATION pi;
    if (!CreateProcessW(ps, line, NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, dir, &si, &pi)) {
        MessageBoxW(NULL, L"Windows PowerShell could not be started.\n\nNo se pudo iniciar Windows PowerShell.", L"Crash Tag Team Racing PC", MB_ICONERROR);
        return 1;
    }
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return 0;
}
