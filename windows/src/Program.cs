using System;
using System.Collections.Specialized;
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
                this.WindowState = FormWindowState.Minimized;
                this.ShowInTaskbar = false;
                this.FormBorderStyle = FormBorderStyle.None;
                CleanupOldScreenshots();
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

                    // If clipboard has an image but no file-drop list yet
                    if (data.GetDataPresent(DataFormats.Bitmap) && !data.GetDataPresent(DataFormats.FileDrop))
                    {
                        using (Image image = Clipboard.GetImage())
                        {
                            if (image != null)
                            {
                                string tempDir = Path.GetTempPath();
                                string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
                                string filename = Path.Combine(tempDir, $"screenshot_{timestamp}.png");

                                image.Save(filename, ImageFormat.Png);

                                // Gold Standard: Bitmap + FileDropList (No plain text string)
                                DataObject newData = new DataObject();
                                newData.SetData(DataFormats.Bitmap, true, image);

                                StringCollection fileList = new StringCollection();
                                fileList.Add(filename);
                                newData.SetFileDropList(fileList);

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
                }
                finally
                {
                    _isProcessing = false;
                }
            }

            private void CleanupOldScreenshots()
            {
                try
                {
                    string tempDir = Path.GetTempPath();
                    DirectoryInfo di = new DirectoryInfo(tempDir);
                    DateTime threshold = DateTime.Now.AddDays(-7);
                    foreach (FileInfo file in di.GetFiles("screenshot_*.png"))
                    {
                        if (file.LastWriteTime < threshold)
                        {
                            try { file.Delete(); } catch { }
                        }
                    }
                }
                catch { }
            }
        }

        [STAThread]
        private static void Main()
        {
            bool createdNew;
            using (Mutex mutex = new Mutex(true, "ScreenshotClipboardSync_SingleInstance", out createdNew))
            {
                if (!createdNew) return;

                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new HiddenClipboardForm());
            }
        }
    }
}
