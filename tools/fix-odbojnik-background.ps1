$ErrorActionPreference = "Stop"

$src = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")) "okladki_marketplace\51-odbojnik-do-grix-plus.png"
$out = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")) "okladki_marketplace\51-odbojnik-do-grix-plus-biale-tlo.png"

$code = @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class FixBackground {
  static bool IsBackground(byte r, byte g, byte b) {
    byte max = Math.Max(r, Math.Max(g, b));
    byte min = Math.Min(r, Math.Min(g, b));
    return max >= 150 && min >= 145 && (max - min) <= 38;
  }

  public static void Run(string src, string dest) {
    using (var original = new Bitmap(src))
    using (var bmp = new Bitmap(original.Width, original.Height, PixelFormat.Format32bppArgb)) {
      using (var g = Graphics.FromImage(bmp)) {
        g.DrawImageUnscaled(original, 0, 0);
      }

      var rect = new Rectangle(700, 315, 835, 665);
      var data = bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
      int bytes = Math.Abs(data.Stride) * bmp.Height;
      byte[] buffer = new byte[bytes];
      Marshal.Copy(data.Scan0, buffer, 0, bytes);

      bool[,] visited = new bool[rect.Width, rect.Height];
      var q = new Queue<Point>();
      for (int x = 0; x < rect.Width; x++) {
        q.Enqueue(new Point(x, 0));
        q.Enqueue(new Point(x, rect.Height - 1));
      }
      for (int y = 0; y < rect.Height; y++) {
        q.Enqueue(new Point(0, y));
        q.Enqueue(new Point(rect.Width - 1, y));
      }

      int[] dx = { 1, -1, 0, 0 };
      int[] dy = { 0, 0, 1, -1 };

      while (q.Count > 0) {
        var p = q.Dequeue();
        if (p.X < 0 || p.Y < 0 || p.X >= rect.Width || p.Y >= rect.Height) continue;
        if (visited[p.X, p.Y]) continue;
        visited[p.X, p.Y] = true;

        int gx = rect.X + p.X;
        int gy = rect.Y + p.Y;
        int i = gy * data.Stride + gx * 4;
        byte b = buffer[i + 0];
        byte g = buffer[i + 1];
        byte r = buffer[i + 2];

        if (!IsBackground(r, g, b)) continue;

        buffer[i + 0] = 255;
        buffer[i + 1] = 255;
        buffer[i + 2] = 255;
        buffer[i + 3] = 255;

        for (int n = 0; n < 4; n++) {
          q.Enqueue(new Point(p.X + dx[n], p.Y + dy[n]));
        }
      }

      Marshal.Copy(buffer, 0, data.Scan0, bytes);
      bmp.UnlockBits(data);
      bmp.Save(dest, ImageFormat.Png);
    }
  }
}
"@

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition $code
[FixBackground]::Run($src, $out)
Get-Item $out | Select-Object FullName, Length, LastWriteTime
