// =====================================================================
//  GeraTrilha (v1.16) - prepara a trilha sonora para as duas versões
//  * mede a sonoridade (LUFS, ITU-R BS.1770: filtro K + blocos de 400 ms
//    com gate) para igualar o volume das músicas entre si
//  * tira o silêncio do começo e do fim e o fade-out longo do final
//  * fecha o LOOP: os últimos segundos se misturam (equal power) com o
//    começo, então a música dá a volta sem corte e sem silêncio
//  * sintetiza o sfx_important_message (impacto metálico grave, original)
//  Lê e grava WAV PCM 16 bits. O ffmpeg do GameMaker faz MP3->WAV e
//  WAV->OGG (ferramentas/converter_trilha.ps1).
// =====================================================================
using System;
using System.IO;
using System.Text;
using System.Collections.Generic;

public static class GeraTrilha
{
    // ------------------------------------------------------------ WAV
    public static float[][] LerWav(string caminho, out int sr)
    {
        byte[] b = File.ReadAllBytes(caminho);
        if (b.Length < 12 || Encoding.ASCII.GetString(b, 0, 4) != "RIFF" || Encoding.ASCII.GetString(b, 8, 4) != "WAVE")
            throw new Exception("WAV invalido: " + caminho);
        int pos = 12, canais = 0, bits = 0, ini = -1, tam = 0;
        sr = 0;
        while (pos + 8 <= b.Length)
        {
            string id = Encoding.ASCII.GetString(b, pos, 4);
            int t = BitConverter.ToInt32(b, pos + 4);
            if (id == "fmt ")
            {
                canais = BitConverter.ToInt16(b, pos + 10);
                sr = BitConverter.ToInt32(b, pos + 12);
                bits = BitConverter.ToInt16(b, pos + 22);
            }
            else if (id == "data")
            {
                ini = pos + 8;
                tam = (t <= 0 || ini + (long)t > b.Length) ? b.Length - ini : t;
                break;
            }
            if (t < 0) break;
            pos += 8 + t + (t & 1);
        }
        if (ini < 0 || bits != 16 || canais < 1) throw new Exception("WAV precisa ser PCM 16 bits: " + caminho);
        int n = tam / (2 * canais);
        float[][] ch = new float[canais][];
        for (int c = 0; c < canais; c++) ch[c] = new float[n];
        int p = ini;
        for (int i = 0; i < n; i++)
            for (int c = 0; c < canais; c++) { ch[c][i] = (short)(b[p] | (b[p + 1] << 8)) / 32768f; p += 2; }
        return ch;
    }

    public static void SalvarWav(string caminho, float[][] ch, int sr)
    {
        int canais = ch.Length, n = ch[0].Length;
        int dados = n * canais * 2;
        byte[] buf = new byte[dados];
        Random rng = new Random(7);
        int p = 0;
        for (int i = 0; i < n; i++)
            for (int c = 0; c < canais; c++)
            {
                double v = ch[c][i] * 32767.0 + (rng.NextDouble() - rng.NextDouble());     // dither TPDF
                int q = (int)Math.Round(v);
                if (q > 32767) q = 32767; else if (q < -32768) q = -32768;
                buf[p++] = (byte)(q & 0xFF);
                buf[p++] = (byte)((q >> 8) & 0xFF);
            }
        using (FileStream fs = new FileStream(caminho, FileMode.Create, FileAccess.Write))
        using (BinaryWriter w = new BinaryWriter(fs))
        {
            w.Write(Encoding.ASCII.GetBytes("RIFF")); w.Write(36 + dados);
            w.Write(Encoding.ASCII.GetBytes("WAVEfmt ")); w.Write(16);
            w.Write((short)1); w.Write((short)canais); w.Write(sr); w.Write(sr * canais * 2);
            w.Write((short)(canais * 2)); w.Write((short)16);
            w.Write(Encoding.ASCII.GetBytes("data")); w.Write(dados);
            w.Write(buf);
        }
    }

    static float MaxAbs(float[][] ch, int i)
    {
        float m = 0;
        for (int c = 0; c < ch.Length; c++) { float v = Math.Abs(ch[c][i]); if (v > m) m = v; }
        return m;
    }

    static double Pico(float[][] ch)
    {
        double m = 0;
        for (int c = 0; c < ch.Length; c++) foreach (float v in ch[c]) if (Math.Abs(v) > m) m = Math.Abs(v);
        return m;
    }

    // ------------------------------------------------------------ SONORIDADE (LUFS)
    // energia K-ponderada (filtros do libebur128) somada em segmentos de 100 ms
    static double[] SegmentosK(float[][] ch, int sr, int ini, int fim, int seg)
    {
        int nseg = Math.Max(0, (fim - ini) / seg);
        double[] e = new double[nseg];
        double f0 = 1681.974450955533, G = 3.999843853973347, Q = 0.7071752369554196;
        double K = Math.Tan(Math.PI * f0 / sr);
        double Vh = Math.Pow(10.0, G / 20.0);
        double Vb = Math.Pow(Vh, 0.4996667741545416);
        double a0 = 1.0 + K / Q + K * K;
        double pb0 = (Vh + Vb * K / Q + K * K) / a0, pb1 = 2.0 * (K * K - Vh) / a0, pb2 = (Vh - Vb * K / Q + K * K) / a0;
        double pa1 = 2.0 * (K * K - 1.0) / a0, pa2 = (1.0 - K / Q + K * K) / a0;
        f0 = 38.13547087602444; Q = 0.5003270373238773;
        K = Math.Tan(Math.PI * f0 / sr);
        double ra1 = 2.0 * (K * K - 1.0) / (1.0 + K / Q + K * K), ra2 = (1.0 - K / Q + K * K) / (1.0 + K / Q + K * K);
        int total = nseg * seg;
        for (int c = 0; c < ch.Length; c++)
        {
            float[] s = ch[c];
            double sx1 = 0, sx2 = 0, sy1 = 0, sy2 = 0, tx1 = 0, tx2 = 0, tz1 = 0, tz2 = 0;
            for (int i = 0; i < total; i++)
            {
                double x = s[ini + i];
                double w = pb0 * x + pb1 * sx1 + pb2 * sx2 - pa1 * sy1 - pa2 * sy2;
                sx2 = sx1; sx1 = x; sy2 = sy1; sy1 = w;
                double z = w - 2.0 * tx1 + tx2 - ra1 * tz1 - ra2 * tz2;
                tx2 = tx1; tx1 = w; tz2 = tz1; tz1 = z;
                e[i / seg] += z * z;
            }
        }
        return e;
    }

    // sonoridade de cada bloco de 400 ms (passo de 100 ms), em LUFS
    static double[] Blocos(double[] e, int seg)
    {
        int nb = Math.Max(0, e.Length - 3);
        double[] l = new double[nb];
        for (int j = 0; j < nb; j++)
        {
            double z = (e[j] + e[j + 1] + e[j + 2] + e[j + 3]) / (4.0 * seg);
            l[j] = z > 1e-12 ? -0.691 + 10 * Math.Log10(z) : -200;
        }
        return l;
    }

    static double Integrada(double[] l)
    {
        double soma = 0; int n = 0;
        foreach (double v in l) if (v > -70) { soma += Math.Pow(10, (v + 0.691) / 10); n++; }
        if (n == 0) return -200;
        double rel = -0.691 + 10 * Math.Log10(soma / n) - 10;
        soma = 0; n = 0;
        foreach (double v in l) if (v > -70 && v > rel) { soma += Math.Pow(10, (v + 0.691) / 10); n++; }
        return n == 0 ? -200 : -0.691 + 10 * Math.Log10(soma / n);
    }

    public static double Lufs(float[][] ch, int sr)
    {
        int seg = sr / 10;
        double[] e = SegmentosK(ch, sr, 0, ch[0].Length, seg);
        if (e.Length < 4)
        {
            // som curto (menos de 400 ms): um bloco só
            double s = 0; foreach (double v in e) s += v;
            return e.Length == 0 || s <= 0 ? -200 : -0.691 + 10 * Math.Log10(s / (e.Length * seg));
        }
        return Integrada(Blocos(e, seg));
    }

    // relatório para escolher os cortes: duração, LUFS, pico e o volume
    // segundo a segundo no começo e no fim
    public static string Medir(string caminho)
    {
        int sr; float[][] ch = LerWav(caminho, out sr);
        int n = ch[0].Length, seg = sr / 10;
        double[] l = Blocos(SegmentosK(ch, sr, 0, n, seg), seg);
        StringBuilder r = new StringBuilder();
        r.AppendFormat("{0}: {1:0.0}s  {2:0.0} LUFS  pico {3:0.0} dBFS", Path.GetFileNameWithoutExtension(caminho),
            (double)n / sr, Lufs(ch, sr), 20 * Math.Log10(Math.Max(1e-9, Pico(ch))));
        int seg_s = l.Length / 10;
        if (seg_s > 0)
        {
            r.Append("\n  inicio:");
            for (int s = 0; s < Math.Min(16, seg_s); s++) r.AppendFormat(" {0:0}", PorSegundo(l, s));
            r.Append("\n  fim:   ");
            for (int s = Math.Max(0, seg_s - 30); s < seg_s; s++) r.AppendFormat(" {0:0}", PorSegundo(l, s));
        }
        return r.ToString();
    }

    static double PorSegundo(double[] l, int s)
    {
        double soma = 0; int n = 0;
        for (int j = s * 10; j < Math.Min(l.Length, s * 10 + 10); j++) { soma += Math.Pow(10, (l[j] + 0.691) / 10); n++; }
        return n == 0 || soma <= 0 ? -99 : Math.Max(-99, -0.691 + 10 * Math.Log10(soma / n));
    }

    // ------------------------------------------------------------ LOOP
    // Prepara uma música para tocar em loop: tira o silêncio, corta o trecho
    // final que já caiu "queda_db" abaixo do volume típico (o fade-out),
    // mistura os últimos "cruzar_s" segundos com o começo e iguala o volume.
    // A saída começa "cruzar_s" depois do começo original: o fim da saída
    // desemboca exatamente no começo dela (loop sem emenda).
    public static string Loop(string entrada, string saida, double alvo_lufs, double cruzar_s, double queda_db)
    {
        int sr; float[][] ch = LerWav(entrada, out sr);
        int n = ch[0].Length, seg = sr / 10;
        const float LIMIAR = 0.0035f;                      // ~ -49 dBFS
        int ini = 0; while (ini < n - 1 && MaxAbs(ch, ini) < LIMIAR) ini++;
        int fim = n; while (fim > ini + 1 && MaxAbs(ch, fim - 1) < LIMIAR) fim--;
        double[] l = Blocos(SegmentosK(ch, sr, ini, fim, seg), seg);
        List<double> v = new List<double>();
        foreach (double x in l) if (x > -70) v.Add(x);
        v.Sort();
        double tipico = v.Count > 0 ? v[v.Count / 2] : -20;
        int ult = l.Length - 1;
        while (ult > 0 && l[ult] < tipico - queda_db) ult--;
        int fim_cheio = ini + (ult + 4) * seg;
        if (fim_cheio < fim) fim = fim_cheio;
        int L = fim - ini;
        int c = (int)(cruzar_s * sr);
        if (L < 4 * c) throw new Exception("musica curta demais para o loop: " + entrada);
        int m = L - c;
        float[][] o = new float[ch.Length][];
        for (int k = 0; k < ch.Length; k++)
        {
            float[] s = ch[k], d = new float[m];
            for (int i = 0; i < m; i++) d[i] = s[ini + c + i];
            for (int i = 0; i < c; i++)
            {
                double t = (i + 0.5) / c;
                int j = m - c + i;
                d[j] = (float)(s[ini + c + j] * Math.Cos(t * Math.PI / 2) + s[ini + i] * Math.Sin(t * Math.PI / 2));
            }
            o[k] = d;
        }
        double lufs = Lufs(o, sr);
        double ganho = Math.Pow(10, (alvo_lufs - lufs) / 20);
        double pico = Pico(o);
        bool limitado = false;
        if (pico * ganho > 0.89) { ganho = 0.89 / pico; limitado = true; }       // nunca acima de -1 dBFS
        for (int k = 0; k < o.Length; k++) for (int i = 0; i < m; i++) o[k][i] = (float)(o[k][i] * ganho);
        SalvarWav(saida, o, sr);
        return string.Format("{0}: {1:0.0}s -> loop de {2:0.0}s (trecho {3:0.0}s..{4:0.0}s, mistura {5:0.0}s, tipico {6:0.0})  {7:0.0} -> {8:0.0} LUFS{9}",
            Path.GetFileNameWithoutExtension(saida), (double)n / sr, (double)m / sr, (double)ini / sr, (double)fim / sr, cruzar_s,
            tipico, lufs, lufs + 20 * Math.Log10(ganho), limitado ? " (limitado pelo pico)" : "");
    }

    // ------------------------------------------------------------ SFX: MENSAGEM IMPORTANTE
    // Um golpe de martelo numa barra de ferro grossa: modos inarmônicos de uma
    // barra (o "clang"), um grave que cai (o peso do golpe), o estalo do
    // martelo e a cauda de um salão de pedra. Curto (1,8 s) e grave.
    public static string Aviso(string saida, double alvo_lufs)
    {
        int sr = 44100;
        double dur = 1.8;
        int n = (int)(dur * sr);
        double[] seco = new double[n];
        Random rng = new Random(1987);
        double f = 92.5;                                                    // fá sustenido grave
        double[] razao = { 1.0, 2.756, 5.404, 8.933, 13.344, 18.64 };       // modos de uma barra livre
        double[] amp = { 0.55, 0.36, 0.22, 0.13, 0.08, 0.05 };
        double[] dec = { 2.4, 3.6, 5.2, 7.5, 10.5, 15.0 };
        double fase = 0, lp = 0, lp2 = 0;
        double a1 = 1 - Math.Exp(-2 * Math.PI * 2600.0 / sr);
        double a2 = 1 - Math.Exp(-2 * Math.PI * 300.0 / sr);
        for (int i = 0; i < n; i++)
        {
            double t = (double)i / sr;
            double v = 0;
            for (int k = 0; k < razao.Length; k++)
            {
                double fk = f * razao[k];
                double e = Math.Exp(-t * dec[k]);
                v += amp[k] * e * (Math.Sin(2 * Math.PI * fk * t) + 0.45 * Math.Sin(2 * Math.PI * fk * 1.0047 * t + k * 1.3));
            }
            double fq = 46 + 74 * Math.Exp(-t * 16);                       // o peso: 120 Hz caindo para 46 Hz
            fase += 2 * Math.PI * fq / sr;
            v += 1.0 * Math.Sin(fase) * Math.Exp(-t * 6.5);
            double r = rng.NextDouble() * 2 - 1;                            // o estalo: ruído passa-faixa curto
            lp += a1 * (r - lp);
            lp2 += a2 * (lp - lp2);
            v += 0.9 * (lp - lp2) * Math.Exp(-t * 55);
            v *= Math.Min(1.0, t / 0.0015);
            seco[i] = v;
        }
        double ps = 0; foreach (double x in seco) if (Math.Abs(x) > ps) ps = Math.Abs(x);
        for (int i = 0; i < n; i++) seco[i] *= 0.8 / ps;
        float[][] o = new float[2][];
        for (int c = 0; c < 2; c++)
        {
            double[] molhado = Salao(seco, sr, c == 0 ? new double[] { 29.7, 37.1, 41.1, 43.7 } : new double[] { 31.3, 36.2, 40.3, 45.1 }, 0.78);
            float[] d = new float[n];
            for (int i = 0; i < n; i++)
            {
                double t = (double)i / sr;
                double v = seco[i] + 0.32 * molhado[i];
                v = Math.Tanh(1.4 * v) / Math.Tanh(1.4);                     // um pouco de aspereza (ferro)
                double fo = t > dur - 0.45 ? (dur - t) / 0.45 : 1;
                d[i] = (float)(v * fo * fo);
            }
            o[c] = d;
        }
        double lufs = Lufs(o, sr);
        double ganho = Math.Pow(10, (alvo_lufs - lufs) / 20);
        double pico = Pico(o);
        if (pico * ganho > 0.89) ganho = 0.89 / pico;
        for (int c = 0; c < 2; c++) for (int i = 0; i < n; i++) o[c][i] = (float)(o[c][i] * ganho);
        SalvarWav(saida, o, sr);
        return string.Format("{0}: {1:0.0}s  {2:0.0} LUFS  pico {3:0.0} dBFS", Path.GetFileNameWithoutExtension(saida), dur,
            lufs + 20 * Math.Log10(ganho), 20 * Math.Log10(pico * ganho));
    }

    // reverb de Schroeder: 4 pentes amortecidos em paralelo + 2 passa-tudo
    static double[] Salao(double[] x, int sr, double[] pentes_ms, double g)
    {
        int n = x.Length;
        double[] y = new double[n];
        foreach (double ms in pentes_ms)
        {
            int D = (int)(ms * sr / 1000);
            double[] buf = new double[n];
            double amort = 0;
            for (int i = 0; i < n; i++)
            {
                double atras = i >= D ? buf[i - D] : 0;
                amort = 0.7 * atras + 0.3 * amort;
                buf[i] = x[i] + g * amort;
                y[i] += atras;
            }
        }
        for (int i = 0; i < n; i++) y[i] /= pentes_ms.Length;
        y = PassaTudo(y, (int)(5.0 * sr / 1000), 0.7);
        y = PassaTudo(y, (int)(1.7 * sr / 1000), 0.7);
        return y;
    }

    static double[] PassaTudo(double[] x, int D, double g)
    {
        int n = x.Length;
        double[] y = new double[n];
        for (int i = 0; i < n; i++)
        {
            double xd = i >= D ? x[i - D] : 0;
            double yd = i >= D ? y[i - D] : 0;
            y[i] = -g * x[i] + xd + g * yd;
        }
        return y;
    }
}
