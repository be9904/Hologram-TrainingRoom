#include <UnityInstancing.cginc>
sampler2D _MainTex, _DetailTex, _DetailMask;
float4 _MainTex_ST, _DetailTex_ST;

sampler2D _NormalMap, _DetailNormalMap;
float _BumpScale, _DetailBumpScale;

sampler2D _MetallicMap;
float _Metallic;
float _Smoothness;

sampler2D _ParallaxMap;
float _ParallaxStrength;

sampler2D _OcclusionMap;
float _OcclusionStrength;

sampler2D _EmissionMap;
float3 _Emission;

float _Cutoff;

struct Attributes
{
    UNITY_VERTEX_INPUT_INSTANCE_ID
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;
};

struct v2f
{
    float4 pos : SV_POSITION;
    float4 uv  : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float3 tangent : TEXCOORD2;
    float3 binormal : TEXCOORD3;
    float4 worldPos : TEXCOORD4;
    float3 tangentViewDir: TEXCOORD5;
};