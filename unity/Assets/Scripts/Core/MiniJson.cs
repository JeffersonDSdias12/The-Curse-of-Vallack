// =====================================================================
//  MiniJson — leitor de JSON pequeno (o JsonUtility do Unity não lê listas
//  mistas como ["casa_a", 120, 641, 1, 0, 3, 2] do cenário da Fase 1).
//  Devolve Dictionary<string, object>, List<object>, double, string, bool.
// =====================================================================
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

public static class MiniJson
{
    public static object Ler(string s) { int i = 0; return Valor(s, ref i); }

    public static Dictionary<string, object> D(object o) => o as Dictionary<string, object>;
    public static List<object> L(object o) => o as List<object> ?? new List<object>();
    public static float F(object o) => o == null ? 0f : Convert.ToSingle(o, CultureInfo.InvariantCulture);
    public static int I(object o) => o == null ? 0 : Convert.ToInt32(o, CultureInfo.InvariantCulture);

    static void Pular(string s, ref int i) { while (i < s.Length && char.IsWhiteSpace(s[i])) i++; }

    static object Valor(string s, ref int i)
    {
        Pular(s, ref i);
        char c = s[i];
        if (c == '{')
        {
            var d = new Dictionary<string, object>();
            i++; Pular(s, ref i);
            if (s[i] == '}') { i++; return d; }
            while (true)
            {
                Pular(s, ref i);
                string k = (string)Valor(s, ref i);
                Pular(s, ref i); i++;                 // ':'
                d[k] = Valor(s, ref i);
                Pular(s, ref i);
                if (s[i++] == ',') continue;
                return d;                              // '}'
            }
        }
        if (c == '[')
        {
            var l = new List<object>();
            i++; Pular(s, ref i);
            if (s[i] == ']') { i++; return l; }
            while (true)
            {
                l.Add(Valor(s, ref i));
                Pular(s, ref i);
                if (s[i++] == ',') continue;
                return l;                              // ']'
            }
        }
        if (c == '"')
        {
            var sb = new StringBuilder();
            i++;
            while (s[i] != '"')
            {
                if (s[i] == '\\')
                {
                    i++;
                    char e = s[i];
                    if (e == 'n') sb.Append('\n');
                    else if (e == 't') sb.Append('\t');
                    else if (e == 'u') { sb.Append((char)int.Parse(s.Substring(i + 1, 4), NumberStyles.HexNumber)); i += 4; }
                    else sb.Append(e);
                }
                else sb.Append(s[i]);
                i++;
            }
            i++;
            return sb.ToString();
        }
        if (c == 't') { i += 4; return true; }
        if (c == 'f') { i += 5; return false; }
        if (c == 'n') { i += 4; return null; }
        int ini = i;
        while (i < s.Length && "+-0123456789.eE".IndexOf(s[i]) >= 0) i++;
        return double.Parse(s.Substring(ini, i - ini), CultureInfo.InvariantCulture);
    }
}
