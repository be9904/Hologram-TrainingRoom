Shader "Unlit/Hologram"
{
    Properties
    {
        [HDR]_MainColor ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Hologram Texture", 2D) = "white" {}
        _AlphaCutout ("Alpha", Range(0,1)) = 0
        
        [HDR]_RimColor ("Rim Light Color", Color) = (1,1,1,1)
        _RimPower ("Rim Light Power", Range(0.1, 5)) = 4.0
        _ScrollSpeed ("Texture Scroll Speed", Range(0, 5)) = 2.0
    }
    SubShader
    {
        Tags { 
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="TransparentCutout"
            "Queue"="AlphaTest"
        }

        Pass
        {
            Name "Universal Forward"
            Tags {"LightMode"="UniversalForward"}

            ZTest LEqual

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            Texture2D _MainTex;
            float4 _MainTex_ST;
            SamplerState sampler_MainTex;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainColor;
            float _AlphaCutout;
            float4 _RimColor;
            float _RimPower;
            float _ScrollSpeed;
            CBUFFER_END

            struct Attributes
            {
                float4 pos      : POSITION;
                float3 normal   : NORMAL;
                float2 uv       : TEXCOORD0;
            };

            struct v2f
            {
                float4 cpos     : SV_POSITION;
                float3 normal   : NORMAL;
                float2 uv       : TEXCOORD0;
                float3 viewDir  : TEXCOORD1;
                float3 wpos     : TEXCOORD2;
            };

            v2f vert (Attributes v)
            {
                v2f o;

                // Transform to world space
                o.wpos = TransformObjectToWorld(v.pos.xyz);
                // Transform to clip space
                o.cpos = TransformObjectToHClip(v.pos.xyz);
                // normalized normals
                o.normal = TransformObjectToWorldNormal(v.normal);
                // sample texture
                o.uv = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.xy = float2(0, (o.wpos.y + _Time.x * _ScrollSpeed) * _MainTex_ST.y + _MainTex_ST.w);
                // compute view direction
                o.viewDir = normalize(
                    _WorldSpaceCameraPos.xyz
                    - mul(UNITY_MATRIX_M, float4(v.pos.xyz, 1.0f)).xyz);

                
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // rim light
                half rimLight = pow((1.0 - saturate(dot(normalize(i.normal), normalize(i.viewDir)))), _RimPower);
                _RimColor *= rimLight * rimLight * rimLight;
                // sample the texture
                half4 color = _MainTex.Sample(sampler_MainTex, i.uv);
                color *= _MainColor;
                color += _RimColor;
                clip(color.a-_AlphaCutout);
                return color;
            }
            ENDHLSL
        }
    }
}
