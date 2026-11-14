// Partículas e brilhos da Vallack: textura x cor do vértice, sem luz 2D.
// _Src/_Dst escolhem a mistura: aditiva (fogo, brasas, janelas, luar) ou
// alfa comum (fumaça, chuva). Sem LightMode: o Renderer 2D desenha como
// SRPDefaultUnlit, na ordem das sorting layers.
Shader "Vallack/Particula"
{
    Properties
    {
        _MainTex ("Textura", 2D) = "white" {}
        [Enum(UnityEngine.Rendering.BlendMode)] _Src ("Origem", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _Dst ("Destino", Float) = 1
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        Pass
        {
            Blend [_Src] [_Dst]
            ZWrite Off
            Cull Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            struct Entrada { float4 pos : POSITION; half4 cor : COLOR; float2 uv : TEXCOORD0; };
            struct Saida { float4 pos : SV_POSITION; half4 cor : COLOR; float2 uv : TEXCOORD0; };

            Saida vert(Entrada i)
            {
                Saida o;
                o.pos = TransformObjectToHClip(i.pos.xyz);
                o.cor = i.cor;
                o.uv = i.uv;
                return o;
            }

            half4 frag(Saida i) : SV_Target
            {
                return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * i.cor;
            }
            ENDHLSL
        }
    }
}
