//
// sh_pos — correção de cor de cinema na imagem do jogo (só o mundo; o HUD
// é desenhado depois, sem efeito). v1.13: tons MENOS CARTUM, mais realistas:
// o roxo neon do fogo maldito apagado, saturação menor, curva de filme
// (contraste nos médios sem estourar), sombras frias, luzes quentes e vinheta.
// A mesma conta está no Godot (G._POS_SHADER).
//
varying vec2 v_vTexcoord;

uniform float u_proporcao;     // largura / altura da tela
uniform vec3 u_sombra;         // tom somado às sombras (frio na fase 1, quente na 2)

const float SATURACAO = 0.78;
const float CURVA = 0.38;      // quanto da curva em S de filme entra
const vec3 LUZ = vec3(1.05, 1.00, 0.92);
const float VINHETA = 0.42;

void main()
{
    vec3 c = texture2D(gm_BaseTexture, v_vTexcoord).rgb;
    // roxo / magenta neon (fogo da maldição, janelas): fica violeta escuro
    float mag = clamp(min(c.r, c.b) - c.g, 0.0, 1.0);
    float l = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(c, vec3(l) * vec3(1.02, 0.92, 1.10), mag * 0.5);
    // menos saturação geral
    l = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(l), c, SATURACAO);
    // curva de filme: contraste nos tons médios, pontas suaves
    c = mix(c, c * c * (3.0 - 2.0 * c), CURVA);
    // luzes quentes, sombras frias
    l = dot(c, vec3(0.299, 0.587, 0.114));
    c *= mix(vec3(1.0), LUZ, smoothstep(0.35, 0.95, l));
    c += u_sombra * (1.0 - smoothstep(0.0, 0.45, l));
    vec2 d = (v_vTexcoord - 0.5) * vec2(u_proporcao, 1.0);
    float v = 1.0 - smoothstep(0.35, 1.15, length(d * vec2(0.62, 1.0)));
    c *= mix(1.0 - VINHETA, 1.0, v);
    gl_FragColor = vec4(clamp(c, 0.0, 1.0), 1.0);
}
