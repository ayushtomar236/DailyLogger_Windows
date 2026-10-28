using System;
using System.Runtime.InteropServices;
using System.Threading;

namespace DailyLogger.App.Services
{
    public sealed class SingleInstanceService : IDisposable
    {
        private const string MutexName = @"Global\DailyLogger_SingleInstance_Mutex";
        private Mutex? _mutex;
        private bool _hasHandle;

        [DllImport("user32.dll", SetLastError = true)]
        private static extern IntPtr FindWindow(string? lpClassName, string lpWindowName);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        private const int SW_RESTORE = 9;

        public bool TryAcquire()
        {
            try
            {
                _mutex = new Mutex(true, MutexName, out _hasHandle);
                return _hasHandle;
            }
            catch (AbandonedMutexException)
            {
                _hasHandle = true;
                return true;
            }
            catch
            {
                return true; // Fallback if security restrictions block global mutex
            }
        }

        public static void ActivateExistingWindow(string windowTitle = "DailyLogger")
        {
            var hWnd = FindWindow(null, windowTitle);
            if (hWnd != IntPtr.Zero)
            {
                ShowWindow(hWnd, SW_RESTORE);
                SetForegroundWindow(hWnd);
            }
        }

        public void Dispose()
        {
            if (_hasHandle && _mutex != null)
            {
                try
                {
                    _mutex.ReleaseMutex();
                }
                catch
                {
                    // Ignore release errors
                }
                _hasHandle = false;
            }
            _mutex?.Dispose();
            _mutex = null;
        }
    }
}
