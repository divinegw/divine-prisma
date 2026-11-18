// Controles desenhados à mão para a janela do instalador, nas cores do Codex DIVINE
// (tema escuro do site da guilda: marinho, ouro e prata).
// Hand-drawn controls for the installer window, in the Codex DIVINE dark palette.
// C# 5: é o que o PowerShell 5.1 compila (sem ?., sem $"", sem inicializador de propriedade).
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Text;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace Divine
{
    public static class Pal
    {
        public static readonly Color Bg       = ColorTranslator.FromHtml("#0a0c11"); // --ink-950
        public static readonly Color Surface  = ColorTranslator.FromHtml("#121620"); // --ink-850
        public static readonly Color Surface2 = ColorTranslator.FromHtml("#191e2a"); // --ink-800
        public static readonly Color Line     = ColorTranslator.FromHtml("#242a38"); // --ink-750
        public static readonly Color LineStrong = ColorTranslator.FromHtml("#303646"); // --ink-700
        public static readonly Color Text     = ColorTranslator.FromHtml("#e4e6ec"); // --ink-75
        public static readonly Color Soft     = ColorTranslator.FromHtml("#c9ccd1"); // --silver-300
        public static readonly Color Mute     = ColorTranslator.FromHtml("#9a9fa6"); // --silver-500
        public static readonly Color Gold     = ColorTranslator.FromHtml("#e2b254"); // --gold-400 (ação)
        public static readonly Color GoldText = ColorTranslator.FromHtml("#eec066"); // --gold-300
        public static readonly Color GoldDeep = ColorTranslator.FromHtml("#ba8d30"); // --gold-500
        public static readonly Color OnGold   = ColorTranslator.FromHtml("#040508"); // --ink-1000
        public static readonly Color Navy900  = ColorTranslator.FromHtml("#0f1c48");
        public static readonly Color Navy800  = ColorTranslator.FromHtml("#16255c");
        public static readonly Color Navy600  = ColorTranslator.FromHtml("#2f479b");
        public static readonly Color Success  = ColorTranslator.FromHtml("#43b369"); // --green-300
        public static readonly Color Danger   = ColorTranslator.FromHtml("#ff6767"); // --red-300

        public static Color Mix(Color a, Color b, double t)
        {
            return Color.FromArgb((int)(a.R + (b.R - a.R) * t), (int)(a.G + (b.G - a.G) * t), (int)(a.B + (b.B - a.B) * t));
        }
        public static Color Alpha(Color c, int a) { return Color.FromArgb(a, c.R, c.G, c.B); }
    }

    public static class Gfx
    {
        public static GraphicsPath Round(RectangleF r, float rad)
        {
            var p = new GraphicsPath();
            float d = Math.Min(rad * 2, Math.Min(r.Width, r.Height));
            if (d <= 0) { p.AddRectangle(r); return p; }
            p.AddArc(r.X, r.Y, d, d, 180, 90);
            p.AddArc(r.Right - d, r.Y, d, d, 270, 90);
            p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
            p.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
            p.CloseFigure();
            return p;
        }

        public static void Smooth(Graphics g)
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
        }

        [DllImport("dwmapi.dll")]
        static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int value, int size);

        // Barra de título escura (Windows 10 20H1+) e na cor do fundo (Windows 11). Falha calada nos antigos.
        public static void DarkTitleBar(IntPtr hwnd, Color caption)
        {
            try
            {
                int on = 1;
                if (DwmSetWindowAttribute(hwnd, 20, ref on, 4) != 0) DwmSetWindowAttribute(hwnd, 19, ref on, 4);
                int bgr = caption.R | (caption.G << 8) | (caption.B << 16);
                DwmSetWindowAttribute(hwnd, 35, ref bgr, 4);
                int txt = Pal.Text.R | (Pal.Text.G << 8) | (Pal.Text.B << 16);
                DwmSetWindowAttribute(hwnd, 36, ref txt, 4);
            }
            catch { }
        }
    }

    public enum Kind { Primary, Secondary, Ghost, Option }

    // Botão arredondado. Kind=Option vira botão de opção (grupo = mesmo Parent + mesmo Group).
    public class DvButton : Control
    {
        bool hover, down, isChecked;
        public Kind Kind;
        public string Group;
        public Image Picture;
        public int Radius;

        public event EventHandler CheckedChanged;

        public DvButton()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                     ControlStyles.ResizeRedraw | ControlStyles.Selectable, true);
            Cursor = Cursors.Hand;
            Radius = 10;
            TabStop = true;
            ForeColor = Pal.Text;
        }

        public bool Checked
        {
            get { return isChecked; }
            set
            {
                if (isChecked == value) return;
                isChecked = value;
                if (value && Parent != null)
                    foreach (Control c in Parent.Controls)
                    {
                        var b = c as DvButton;
                        if (b != null && b != this && b.Kind == Kind.Option && b.Group == Group) b.Checked = false;
                    }
                Invalidate();
                if (CheckedChanged != null) CheckedChanged(this, EventArgs.Empty);
            }
        }

        protected override void OnMouseEnter(EventArgs e) { hover = true; Invalidate(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { hover = false; down = false; Invalidate(); base.OnMouseLeave(e); }
        protected override void OnMouseDown(MouseEventArgs e) { if (e.Button == MouseButtons.Left) { down = true; Focus(); Invalidate(); } base.OnMouseDown(e); }
        protected override void OnMouseUp(MouseEventArgs e) { down = false; Invalidate(); base.OnMouseUp(e); }
        protected override void OnEnabledChanged(EventArgs e) { Cursor = Enabled ? Cursors.Hand : Cursors.Default; Invalidate(); base.OnEnabledChanged(e); }
        protected override void OnGotFocus(EventArgs e) { Invalidate(); base.OnGotFocus(e); }
        protected override void OnLostFocus(EventArgs e) { Invalidate(); base.OnLostFocus(e); }
        protected override void OnTextChanged(EventArgs e) { Invalidate(); base.OnTextChanged(e); }

        protected override void OnClick(EventArgs e)
        {
            if (Kind == Kind.Option) Checked = true;
            base.OnClick(e);
        }

        protected override bool IsInputKey(Keys k) { return k == Keys.Enter || k == Keys.Space || base.IsInputKey(k); }
        protected override void OnKeyUp(KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Enter || e.KeyCode == Keys.Space) OnClick(EventArgs.Empty);
            base.OnKeyUp(e);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            var g = e.Graphics;
            g.Clear(Parent != null ? Parent.BackColor : Pal.Bg);
            Gfx.Smooth(g);

            Color fill, border, text;
            float bw = 1f;
            if (!Enabled)
            {
                fill = Pal.Surface2; border = Pal.Line; text = Pal.Mute;
            }
            else if (Kind == Kind.Primary)
            {
                fill = down ? Pal.GoldDeep : hover ? Pal.GoldText : Pal.Gold; border = fill; text = Pal.OnGold;
            }
            else if (Kind == Kind.Ghost)
            {
                fill = hover ? Pal.Surface2 : (Parent != null ? Parent.BackColor : Pal.Bg); border = fill; text = hover ? Pal.Text : Pal.Soft;
            }
            else if (Kind == Kind.Option && isChecked)
            {
                fill = Pal.Mix(Pal.Surface, Pal.Gold, 0.13); border = Pal.Gold; text = Pal.GoldText; bw = 1.5f;
            }
            else
            {
                fill = hover ? Pal.Surface2 : Pal.Surface; border = hover ? Pal.GoldDeep : (Kind == Kind.Option ? Pal.Line : Pal.LineStrong);
                text = Kind == Kind.Option ? Pal.Soft : Pal.Text;
            }

            var r = new RectangleF(bw / 2, bw / 2, Width - bw - 0.5f, Height - bw - 0.5f);
            using (var p = Gfx.Round(r, Radius))
            {
                using (var b = new SolidBrush(fill)) g.FillPath(b, p);
                using (var pen = new Pen(border, bw)) g.DrawPath(pen, p);
            }

            if (Focused && ShowFocusCues)
                using (var p = Gfx.Round(new RectangleF(3, 3, Width - 7, Height - 7), Math.Max(Radius - 3, 2)))
                using (var pen = new Pen(Pal.GoldText, 2f)) g.DrawPath(pen, p);

            var flags = TextFormatFlags.HorizontalCenter | TextFormatFlags.NoPrefix | TextFormatFlags.EndEllipsis;
            if (Picture != null)
            {
                int textH = Font.Height + 8;
                int area = Height - textH - 6;
                float s = Math.Min((float)area / Picture.Height, (float)(Width - 12) / Picture.Width);
                s = Math.Min(s, 1f);
                float w = Picture.Width * s, h = Picture.Height * s;
                if (!Enabled) { /* imagens sem estado desativado aqui */ }
                g.DrawImage(Picture, (Width - w) / 2, 6 + (area - h) / 2, w, h);
                TextRenderer.DrawText(g, Text, Font, new Rectangle(0, Height - textH - 2, Width, textH), text, fill,
                                      flags | TextFormatFlags.VerticalCenter);
            }
            else
            {
                TextRenderer.DrawText(g, Text, Font, ClientRectangle, text, fill, flags | TextFormatFlags.VerticalCenter);
            }
        }
    }

    // Chave liga/desliga com texto ao lado (quebra linha).
    public class DvToggle : Control
    {
        bool hover, isChecked;
        public event EventHandler CheckedChanged;

        public DvToggle()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                     ControlStyles.ResizeRedraw | ControlStyles.Selectable, true);
            Cursor = Cursors.Hand; TabStop = true; ForeColor = Pal.Soft;
        }

        public bool Checked
        {
            get { return isChecked; }
            set { if (isChecked == value) return; isChecked = value; Invalidate(); if (CheckedChanged != null) CheckedChanged(this, EventArgs.Empty); }
        }

        protected override void OnClick(EventArgs e) { Focus(); Checked = !Checked; base.OnClick(e); }
        protected override void OnMouseEnter(EventArgs e) { hover = true; Invalidate(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { hover = false; Invalidate(); base.OnMouseLeave(e); }
        protected override void OnGotFocus(EventArgs e) { Invalidate(); base.OnGotFocus(e); }
        protected override void OnLostFocus(EventArgs e) { Invalidate(); base.OnLostFocus(e); }
        protected override bool IsInputKey(Keys k) { return k == Keys.Space || base.IsInputKey(k); }
        protected override void OnKeyUp(KeyEventArgs e) { if (e.KeyCode == Keys.Space) OnClick(EventArgs.Empty); base.OnKeyUp(e); }

        protected override void OnPaint(PaintEventArgs e)
        {
            var g = e.Graphics;
            var bg = Parent != null ? Parent.BackColor : Pal.Bg;
            g.Clear(bg);
            Gfx.Smooth(g);
            const int tw = 40, th = 22;
            int ty = 4;
            var track = new RectangleF(1, ty, tw, th);
            using (var p = Gfx.Round(track, th / 2f))
            {
                using (var b = new SolidBrush(isChecked ? Pal.Gold : (hover ? Pal.Surface2 : Pal.Surface))) g.FillPath(b, p);
                using (var pen = new Pen(isChecked ? Pal.Gold : (hover ? Pal.GoldDeep : Pal.LineStrong), 1f)) g.DrawPath(pen, p);
            }
            float k = th - 8;
            float kx = isChecked ? track.Right - k - 4 : track.X + 4;
            using (var b = new SolidBrush(isChecked ? Pal.OnGold : Pal.Soft)) g.FillEllipse(b, kx, ty + 4, k, k);
            if (Focused && ShowFocusCues)
                using (var p = Gfx.Round(new RectangleF(-1, ty - 2, tw + 4, th + 4), (th + 4) / 2f))
                using (var pen = new Pen(Pal.GoldText, 2f)) g.DrawPath(pen, p);
            TextRenderer.DrawText(g, Text, Font, new Rectangle(tw + 12, 0, Width - tw - 12, Height), ForeColor, bg,
                                  TextFormatFlags.WordBreak | TextFormatFlags.NoPrefix | TextFormatFlags.Top);
        }
    }

    // Painel arredondado com borda (o "card" do site).
    public class DvCard : Panel
    {
        public int Radius;
        public Color Border;
        public DvCard()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
            Radius = 10; BackColor = Pal.Surface; Border = Pal.Line;
        }
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            var g = e.Graphics;
            g.Clear(Parent != null ? Parent.BackColor : Pal.Bg);
            Gfx.Smooth(g);
            using (var p = Gfx.Round(new RectangleF(0.5f, 0.5f, Width - 1.5f, Height - 1.5f), Radius))
            {
                using (var b = new SolidBrush(BackColor)) g.FillPath(b, p);
                using (var pen = new Pen(Border, 1f)) g.DrawPath(pen, p);
            }
        }
    }

    // Imagem com cantos arredondados e borda (prévia).
    public class DvImage : Control
    {
        Image img;
        public DvImage()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
        }
        public Image Image
        {
            get { return img; }
            set { var old = img; img = value; Invalidate(); if (old != null && old != value) old.Dispose(); }
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            var g = e.Graphics;
            g.Clear(Parent != null ? Parent.BackColor : Pal.Bg);
            Gfx.Smooth(g);
            using (var p = Gfx.Round(new RectangleF(0.5f, 0.5f, Width - 1.5f, Height - 1.5f), 10))
            {
                if (img != null) { g.SetClip(p); g.DrawImage(img, 0, 0, Width, Height); g.ResetClip(); }
                using (var pen = new Pen(Pal.Line, 1f)) g.DrawPath(pen, p);
            }
        }
    }

    // Linha de estado: ponto colorido + texto, um depois do outro.
    public class DvStatus : Control
    {
        readonly List<KeyValuePair<string, Color>> items = new List<KeyValuePair<string, Color>>();
        public DvStatus()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
            ForeColor = Pal.Soft;
        }
        public void Clear() { items.Clear(); Invalidate(); }
        public void Add(string text, Color dot) { items.Add(new KeyValuePair<string, Color>(text, dot)); Invalidate(); }
        protected override void OnPaint(PaintEventArgs e)
        {
            var g = e.Graphics;
            var bg = Parent != null ? Parent.BackColor : Pal.Bg;
            g.Clear(bg);
            Gfx.Smooth(g);
            int x = 2, y = 0;
            int lh = Font.Height + 4;
            foreach (var it in items)
            {
                var sz = TextRenderer.MeasureText(g, it.Key, Font, new Size(int.MaxValue, lh), TextFormatFlags.NoPadding);
                if (x > 2 && x + 16 + sz.Width > Width) { x = 2; y += lh; }
                using (var b = new SolidBrush(it.Value)) g.FillEllipse(b, x, y + (lh - 8) / 2f, 8, 8);
                TextRenderer.DrawText(g, it.Key, Font, new Point(x + 14, y + 2), ForeColor, bg, TextFormatFlags.NoPadding);
                x += 14 + sz.Width + 20;
            }
        }
    }

    // Faixa do topo: céu marinho com estrelas (o anel da logo), emblema, nome e o cursor escolhido com brilho.
    public class DvHeader : Panel
    {
        public Image Emblem, Showcase;
        public string Title, Subtitle, Note;
        public Font TitleFont, SubFont, NoteFont;
        Color glow;

        public DvHeader()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
            glow = Pal.Gold;
            BackColor = Pal.Bg;
        }

        public Color Glow { get { return glow; } set { glow = value; Invalidate(); } }
        public void SetShowcase(Image im) { var old = Showcase; Showcase = im; Invalidate(); if (old != null && old != im) old.Dispose(); }

        protected override void OnPaintBackground(PaintEventArgs e) { }

        protected override void OnPaint(PaintEventArgs e)
        {
            var g = e.Graphics;
            Gfx.Smooth(g);
            int W = Width, H = Height;
            using (var b = new LinearGradientBrush(new Rectangle(0, 0, W, H), Pal.Navy900, Pal.Bg, 0f))
            {
                var blend = new ColorBlend(3);
                blend.Colors = new[] { Pal.Mix(Pal.Bg, Pal.Navy900, 0.95), Pal.Mix(Pal.Bg, Pal.Navy900, 0.35), Pal.Bg };
                blend.Positions = new[] { 0f, 0.55f, 1f };
                b.InterpolationColors = blend;
                g.FillRectangle(b, 0, 0, W, H);
            }

            // brilho atrás do emblema (marinho) e atrás do cursor (cor escolhida)
            Halo(g, new RectangleF(-60, -70, 300, H + 140), Pal.Alpha(Pal.Navy600, 110));
            Halo(g, new RectangleF(W - 250, -60, 260, H + 120), Pal.Alpha(glow, 80));

            // estrelas fixas (sempre as mesmas)
            var rnd = new Random(11);
            for (int i = 0; i < 70; i++)
            {
                float x = (float)rnd.NextDouble() * W, y = (float)rnd.NextDouble() * (H - 4);
                float s = rnd.NextDouble() < 0.12 ? 2.2f : 1.2f;
                int a = 30 + rnd.Next(110);
                var c = rnd.NextDouble() < 0.3 ? Pal.GoldText : Pal.Soft;
                using (var b = new SolidBrush(Pal.Alpha(c, a))) g.FillEllipse(b, x, y, s, s);
                if (s > 2 && rnd.NextDouble() < 0.6) Spark(g, x + 1, y + 1, 6, Pal.Alpha(c, a));
            }

            // fio de ouro embaixo, apagando nas pontas
            using (var b = new LinearGradientBrush(new Rectangle(0, H - 1, W, 1), Color.Transparent, Color.Transparent, 0f))
            {
                var blend = new ColorBlend(3);
                blend.Colors = new[] { Pal.Alpha(Pal.Gold, 0), Pal.Alpha(Pal.Gold, 170), Pal.Alpha(Pal.Gold, 0) };
                blend.Positions = new[] { 0f, 0.35f, 1f };
                b.InterpolationColors = blend;
                g.FillRectangle(b, 0, H - 1, W, 1);
            }

            int ex = 26, es = 88;
            if (Emblem != null) g.DrawImage(Emblem, ex, (H - es) / 2, es, es);

            float tx = ex + es + 20;
            float ty = (H - 96) / 2f;
            if (TitleFont != null && Title != null)
            {
                TextRenderer.DrawText(g, Title, TitleFont, new Point((int)tx - 3, (int)ty), Pal.Text, TextFormatFlags.NoPadding);
                ty += TitleFont.Height + 2;
            }
            if (SubFont != null && Subtitle != null)
            {
                var flags = TextFormatFlags.WordBreak | TextFormatFlags.NoPadding;
                var box = new Size(W - (int)tx - 170, SubFont.Height * 3);
                int sh = TextRenderer.MeasureText(g, Subtitle, SubFont, box, flags).Height;
                TextRenderer.DrawText(g, Subtitle, SubFont, new Rectangle((int)tx, (int)ty, box.Width, sh), Pal.Soft, flags);
                ty += sh + 8;
            }
            if (NoteFont != null && Note != null)
                TextRenderer.DrawText(g, Note, NoteFont, new Point((int)tx, (int)ty), Pal.GoldText, TextFormatFlags.NoPadding);

            if (Showcase != null)
            {
                int s = Math.Min(Showcase.Width, H - 24);
                g.DrawImage(Showcase, W - s - 46, (H - s) / 2, s, s);
            }
        }

        static void Halo(Graphics g, RectangleF r, Color c)
        {
            using (var path = new GraphicsPath())
            {
                path.AddEllipse(r);
                using (var b = new PathGradientBrush(path))
                {
                    b.CenterColor = c;
                    b.SurroundColors = new[] { Pal.Alpha(c, 0) };
                    g.FillPath(b, path);
                }
            }
        }

        // estrela de quatro pontas, como as do anel da logo
        static void Spark(Graphics g, float x, float y, float r, Color c)
        {
            using (var p = new GraphicsPath())
            {
                float k = r * 0.22f;
                p.AddPolygon(new[] {
                    new PointF(x, y - r), new PointF(x + k, y - k), new PointF(x + r, y), new PointF(x + k, y + k),
                    new PointF(x, y + r), new PointF(x - k, y + k), new PointF(x - r, y), new PointF(x - k, y - k) });
                using (var b = new SolidBrush(c)) g.FillPath(b, p);
            }
        }
    }
}
