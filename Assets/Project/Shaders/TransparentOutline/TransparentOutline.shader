Shader "Custom/TransparentOutline"
{
    Properties {
		_Color ("Main Color", Color) = (.5,.5,.5,1)
		_OutlineColor ("Outline Color", Color) = (0,0,0,1)
		_Outline ("Outline width", Range (0.0, 0.15)) = .005
		_OutlineOffset ("Outline Offset", Vector) = (0, 0, 0)
		_MainTex ("Base (RGB)", 2D) = "white" { }
		_Alpha ("Alpha", Float) = 1
	}
 
	HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
		 
		struct appdata {
			half4 vertex : POSITION;
			half3 normal : NORMAL;
			half2 texcoord : TEXCOORD0;
		};
		 
		struct v2f {
			half4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half3 normalDir : NORMAL;
		};
		 
		uniform half4 _Color;
		uniform half _Outline;
		uniform half4 _OutlineColor;
		float _Alpha;
		 
	ENDHLSL
 
	SubShader {
		Tags { 
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="TransparentCutout"
			"Queue" = "AlphaTest"
		}
		
		Pass {
			Name "OUTLINE"
			Tags { "LightMode" = "SRPDefaultUnlit" }
			Cull Front
			
			Stencil {
                Ref 2
                /*Comp Always
				Pass Replace
				Fail Keep
				ZFail Replace*/
			}

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			half3 _OutlineOffset;
			
			v2f vert(appdata v) {
				v2f o;
				
				half3 vertex = v.vertex.xyz;
				vertex -= _OutlineOffset;
				vertex.x *= _Outline+1;
				vertex.y *= _Outline+1;
				vertex.z *= _Outline+1;	
				vertex += _OutlineOffset;
				o.pos = TransformObjectToHClip(vertex);
				o.uv = v.texcoord;
				o.normalDir = TransformObjectToWorldNormal(v.normal);
			 
				return o;
			}
			
			half4 frag(v2f i) : SV_Target {
				return _OutlineColor;
			}
			ENDHLSL
		}
 
 		Pass {
			Name "STENCIL"
 			Tags {"LightMode"="UniversalForward"}
			
 			Blend SrcAlpha OneMinusSrcAlpha
 			
			Stencil {
                Ref 1
				/*Comp Never
				Pass Replace
				Fail Keep
				ZFail Replace*/
            }
			
			HLSLPROGRAM

			#pragma vertex vert2
			#pragma fragment frag
						
			v2f vert2 (appdata v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex.xyz);
				o.uv = v.texcoord;
				o.normalDir = TransformObjectToWorldNormal(v.normal);
		
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half4 color = half4(1,0,0,0);
				return color;
			}
			
			ENDHLSL


		}
	}
}
