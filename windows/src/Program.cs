using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

namespace ScreenshotClipboardSync
{
    internal static class Program
    {
        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool AddClipboardFormatListener(IntPtr hwnd);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool RemoveClipboardFormatListener(IntPtr hwnd);

        private const int WM_CLIPBOARDUPDATE = 0x031D;

        private class HiddenClipboardForm : Form
        {
            private bool _isProcessing = false;

            public HiddenClipboardForm()
            {
                // Create a message-only / hidden window
                this.WindowState = FormWindowState.Minimized;
                this.ShowInTaskbar = false;
                this.FormBorderStyle = FormBorderStyle.None;
            }

            protected override void OnLoad(EventArgs e)
            {
                base.OnLoad(e);
                this.Visible = false;
                AddClipboardFormatListener(this.Handle);
            }

            protected override void OnFormClosing(FormClosingEventArgs e)
            {
                RemoveClipboardFormatListener(this.Handle);
                base.OnFormClosing(e);
            }

            protected override void WndProc(ref Message m)
            {
                if (m.Msg == WM_CLIPBOARDUPDATE)
                {
                    if (!_isProcessing)
                    {
                        ProcessClipboard();
                    }
                }
                base.WndProc(ref m);
            }

            private void ProcessClipboard()
            {
                try
                {
                    _isProcessing = true;

                    // Retry up to 5 times in case another app is still writing to clipboard
                    IDataObject data = null;
                    for (int i = 0; i < 5; i++)
                    {
                        try
                        {
                            data = Clipboard.GetDataObject();
                            if (data != null) break;
                        }
                        catch
                        {
                            Thread.Sleep(50);
                        }
                    }

                    if (data == null) return;

                    // Check if clipboard contains an image
                    if (data.GetDataPresent(DataFormats.Bitmap))
                    {
                        // Check if text is already present and if it's already our generated path
                        string currentText = null;
                        if (data.GetDataPresent(DataFormats.UnicodeText))
                        {
                            currentText = data.GetData(DataFormats.UnicodeText) as string;
                        }

                        string tempDir = Path.GetTempPath();
                        if (!string.IsNullOrEmpty(currentText) && currentText.StartsWith(tempDir))
                        {
                            // Already processed, avoid infinite loop
                            return;
                        }

                        // Retrieve the image
                        using (Image image = Clipboard.GetImage())
                        {
                            if (image != null)
                            {
                                string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
                                string filename = Path.Combine(tempDir, $"screenshot_{timestamp}.png");

                                // Save image to Windows Temp directory (%TEMP%)
                                image.Save(filename, ImageFormat.Png);

                                // Construct dual-flavor clipboard (Image + Text file path)
                                DataObject newData = new DataObject();
                                newData.SetData(DataFormats.Bitmap, true, image);
                                newData.SetData(DataFormats.UnicodeText, true, filename);

                                // Retry setting clipboard
                                for (int i = 0; i < 5; i++)
                                {
                                    try
                                    {
                                        Clipboard.SetDataObject(newData, true);
                                        break;
                                    }
                                    catch
                                    {
                                        Thread.Sleep(50);
                                    }
                                }
                            }
                        }
                    }
                }
                catch
                {
                    // Silently ignore transient errors
                }
                finally
                {
                    _isProcessing = false;
                }
            }
        }

        [STAThread]
        private static void Main()
        {
            // Ensure single instance
            bool createdNew;
            using (Mutex mutex = new Mutex(true, "ScreenshotClipboardSync_SingleInstance", out createdNew))
            {
                if (!createdNew)
                {
                    return;
                }

                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new HiddenClipboardForm());
            }
        }
    }
}
