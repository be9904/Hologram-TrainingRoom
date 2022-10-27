Shader "Custom/Rimlight"
{
	Properties
	{
		[HDR]_MainTexColor("Noise Color", Color) = (1,1,1,1)
		_MainTex("Noise Texture", 2D) = "white" {}
		_Cutout ("Cutout", Range(0,1)) = 0.5
		
		[HDR]_RimLightColor ("RimLight Color", Color) = (1, 1, 1, 1)
		_RimLightPower ("RimLight Power", Range(2,5)) = 2
		
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
	}

	SubShader{

		Tags {
			"RenderType" = "TransparentCutout"
			"Queue" = "AlphaTest"
			"RenderPipeline" = "UniversalPipeline"
		}

		Pass {
			Tags {"LightMode"="SRPDefaultUnlit"}
			HLSLPROGRAM
			#pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            
            //cg shader는 .cginc를 hlsl shader는 .hlsl을 include하게 됩니다.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			float4 _MainTex_ST;
			Texture2D _MainTex;
			SamplerState sampler_MainTex;
			
			CBUFFER_START(UnityPerMaterial)
				float4 _MainTexColor;
				float _Cutout;
			CBUFFER_END
			
			//vertex buffer에서 읽어올 정보를 선언합니다.
            struct VertexInput
            {
                float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            //보간기를 통해 버텍스 셰이더에서 픽셀 셰이더로 전달할 정보를 선언합니다.
            struct VertexOutput
            {
                float4 vertex : SV_POSITION;
            	float2 uv : TEXCOORD0;
				UNITY_VERTEX_OUTPUT_STEREO
            };
            
            //버텍스 셰이더
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;

            	UNITY_SETUP_INSTANCE_ID(v); //Insert
			    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); //Insert

            	o.vertex = TransformObjectToHClip(v.vertex.xyz);
            	o.uv = v.uv * _MainTex_ST.xy + _MainTex_ST.zw;
            	
                return o;
            }
            
            //픽셀 셰이더
            half4 frag(VertexOutput i) : SV_Target
            {
            	float4 noise = _MainTex.Sample(sampler_MainTex, i.uv);
            	clip(noise.a - _Cutout);
            	noise *= _MainTexColor;
            	
                return noise;
            }
			
			ENDHLSL
		}
		
		Pass {
			Tags {"LightMode"="UniversalForward"}
			Blend [_SrcBlend] [_DstBlend]
			
			HLSLPROGRAM
			#pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            
            //cg shader는 .cginc를 hlsl shader는 .hlsl을 include하게 됩니다.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			CBUFFER_START(UnityPerMaterial)
				float4 _RimLightColor;
				float _RimLightPower;
			CBUFFER_END
			
			//vertex buffer에서 읽어올 정보를 선언합니다.
            struct VertexInput
            {
                float4 vertex : POSITION;
				float3 normal: NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            //보간기를 통해 버텍스 셰이더에서 픽셀 셰이더로 전달할 정보를 선언합니다.
            struct VertexOutput
            {
                float4 vertex : SV_POSITION;
            	float3 normal: TEXCOORD2;
				float3 viewDir: TEXCOORD3;
				UNITY_VERTEX_OUTPUT_STEREO
            };
            
            //버텍스 셰이더
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;

            	UNITY_SETUP_INSTANCE_ID(v); //Insert
			    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); //Insert

            	o.vertex = TransformObjectToHClip(v.vertex.xyz);
            	o.normal = TransformObjectToWorldNormal(v.normal);
            	o.viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);
            	
                return o;
            }
            
            //픽셀 셰이더
            half4 frag(VertexOutput i) : SV_Target
            {
				// polynomial
            	// float fresnel = pow(1 - saturate(dot(i.normal, i.viewDir)), _FresnelPower);
            	
            	// exponential
            	float fresnel = saturate(pow(abs(_RimLightPower), 1 - saturate(dot(i.normal, i.viewDir))) - 1);
            	clip(fresnel-0.5);
                return fresnel * _RimLightColor;
            }
			
			ENDHLSL
		}
	}
}