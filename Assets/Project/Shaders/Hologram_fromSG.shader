Shader "Custom/Hologram"
{
    Properties
    {
        [HDR]_FresnelColor("Fresnel Color", Color) = (4, 4, 4, 0)
        _FresnelPower("Fresnel Power", Range(0.1, 5)) = 4
        [HDR]_MainColor("Main Color", Color) = (2, 2, 2, 0)
        [NoScaleOffset]_HologramScanlines("Hologram Scanlines", 2D) = "white" {}
        _ScrollSpeed("Scroll Speed", Float) = 0.05
        _HologramTiling("Hologram Tiling", Vector) = (32, 32, 0, 0)
        _FlickerIntensity("Flicker Intensity", Range(0, 1)) = 0.3
        [HideInInspector]_QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector]_QueueControl("_QueueControl", Float) = -1
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "UniversalMaterialType" = "Lit"
            "Queue"="Transparent"
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"="UniversalLitSubTarget"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
        
        // Render State
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DYNAMICLIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
        #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
        #pragma multi_compile_fragment _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        #pragma multi_compile _ _CLUSTERED_RENDERING
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_FORWARD
        #define _FOG_FRAGMENT 1
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _ALPHATEST_ON 1
        #define _RECEIVE_SHADOWS_OFF 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
             float4 fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 TangentSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float3 interp3 : INTERP3;
             float2 interp4 : INTERP4;
             float2 interp5 : INTERP5;
             float3 interp6 : INTERP6;
             float4 interp7 : INTERP7;
             float4 interp8 : INTERP8;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.interp5.xy =  input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp6.xyz =  input.sh;
            #endif
            output.interp7.xyzw =  input.fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.interp8.xyzw =  input.shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.interp4.xy;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.interp5.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp6.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp7.xyzw;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.interp8.xyzw;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _FresnelColor;
        float _FresnelPower;
        float4 _MainColor;
        float4 _HologramScanlines_TexelSize;
        float _ScrollSpeed;
        float2 _HologramTiling;
        float _FlickerIntensity;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_HologramScanlines);
        SAMPLER(sampler_HologramScanlines);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
        {
             float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
             Out = lerp(Min, Max, randomno);
        }
        
        void Unity_Comparison_Greater_float(float A, float B, out float Out)
        {
            Out = A > B ? 1 : 0;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Branch_float(float Predicate, float True, float False, out float Out)
        {
            Out = Predicate ? True : False;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_34c3853187ea406bace159aae5362e16_Out_0 = IsGammaSpace() ? LinearToSRGB(_MainColor) : _MainColor;
            float4 _Property_a75280112a8848f3a168d96b9cb3d871_Out_0 = IsGammaSpace() ? LinearToSRGB(_FresnelColor) : _FresnelColor;
            float _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0 = _FresnelPower;
            float _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0, _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3);
            float4 _Multiply_7b14177af4454643be3c56184b9a8791_Out_2;
            Unity_Multiply_float4_float4(_Property_a75280112a8848f3a168d96b9cb3d871_Out_0, (_FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3.xxxx), _Multiply_7b14177af4454643be3c56184b9a8791_Out_2);
            UnityTexture2D _Property_0a40095baa8747309c5b5457affa6b23_Out_0 = UnityBuildTexture2DStructNoScale(_HologramScanlines);
            float _Split_384d7597729249498e1f8a169331c1aa_R_1 = IN.WorldSpacePosition[0];
            float _Split_384d7597729249498e1f8a169331c1aa_G_2 = IN.WorldSpacePosition[1];
            float _Split_384d7597729249498e1f8a169331c1aa_B_3 = IN.WorldSpacePosition[2];
            float _Split_384d7597729249498e1f8a169331c1aa_A_4 = 0;
            float _Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0 = _ScrollSpeed;
            float _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2;
            Unity_Multiply_float_float(_Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0, IN.TimeParameters.x, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2);
            float _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2;
            Unity_Add_float(_Split_384d7597729249498e1f8a169331c1aa_G_2, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0 = float2(0, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Property_bfe8977265394f82a18fc243a570c5e1_Out_0 = _HologramTiling;
            float2 _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3;
            Unity_TilingAndOffset_float(_Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0, _Property_bfe8977265394f82a18fc243a570c5e1_Out_0, float2 (0, 0), _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3);
            float4 _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0 = SAMPLE_TEXTURE2D(_Property_0a40095baa8747309c5b5457affa6b23_Out_0.tex, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.samplerstate, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.GetTransformedUV(_TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3));
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_R_4 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.r;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_G_5 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.g;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_B_6 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.b;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_A_7 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.a;
            float4 _Add_695108988ba248fcb0f2f77502ddb7df_Out_2;
            Unity_Add_float4(_Multiply_7b14177af4454643be3c56184b9a8791_Out_2, _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0, _Add_695108988ba248fcb0f2f77502ddb7df_Out_2);
            float _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3;
            Unity_RandomRange_float((IN.TimeParameters.x.xx), 0, 1, _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3);
            float _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2;
            Unity_Comparison_Greater_float(_RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3, 0.9, _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2);
            float _Property_d407b1bfba984e5592275c40c747bc5b_Out_0 = _FlickerIntensity;
            float _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1;
            Unity_OneMinus_float(_Property_d407b1bfba984e5592275c40c747bc5b_Out_0, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1);
            float _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3;
            Unity_Branch_float(_Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2, 1, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1, _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3);
            float4 _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2;
            Unity_Multiply_float4_float4(_Add_695108988ba248fcb0f2f77502ddb7df_Out_2, (_Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3.xxxx), _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2);
            surface.BaseColor = (_Property_34c3853187ea406bace159aae5362e16_Out_0.xyz);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Emission = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2.xyz);
            surface.Metallic = 0;
            surface.Smoothness = 0.5;
            surface.Occlusion = 1;
            surface.Alpha = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2).x;
            surface.AlphaClipThreshold = 0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
            output.WorldSpacePosition = input.positionWS;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }
        
        // Render State
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DYNAMICLIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
        #pragma multi_compile_fragment _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
        #pragma multi_compile _ SHADOWS_SHADOWMASK
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_GBUFFER
        #define _FOG_FRAGMENT 1
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _ALPHATEST_ON 1
        #define _RECEIVE_SHADOWS_OFF 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
             float4 fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 TangentSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float3 interp3 : INTERP3;
             float2 interp4 : INTERP4;
             float2 interp5 : INTERP5;
             float3 interp6 : INTERP6;
             float4 interp7 : INTERP7;
             float4 interp8 : INTERP8;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.interp5.xy =  input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp6.xyz =  input.sh;
            #endif
            output.interp7.xyzw =  input.fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.interp8.xyzw =  input.shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.interp4.xy;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.interp5.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp6.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp7.xyzw;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.interp8.xyzw;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _FresnelColor;
        float _FresnelPower;
        float4 _MainColor;
        float4 _HologramScanlines_TexelSize;
        float _ScrollSpeed;
        float2 _HologramTiling;
        float _FlickerIntensity;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_HologramScanlines);
        SAMPLER(sampler_HologramScanlines);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
        {
             float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
             Out = lerp(Min, Max, randomno);
        }
        
        void Unity_Comparison_Greater_float(float A, float B, out float Out)
        {
            Out = A > B ? 1 : 0;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Branch_float(float Predicate, float True, float False, out float Out)
        {
            Out = Predicate ? True : False;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_34c3853187ea406bace159aae5362e16_Out_0 = IsGammaSpace() ? LinearToSRGB(_MainColor) : _MainColor;
            float4 _Property_a75280112a8848f3a168d96b9cb3d871_Out_0 = IsGammaSpace() ? LinearToSRGB(_FresnelColor) : _FresnelColor;
            float _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0 = _FresnelPower;
            float _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0, _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3);
            float4 _Multiply_7b14177af4454643be3c56184b9a8791_Out_2;
            Unity_Multiply_float4_float4(_Property_a75280112a8848f3a168d96b9cb3d871_Out_0, (_FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3.xxxx), _Multiply_7b14177af4454643be3c56184b9a8791_Out_2);
            UnityTexture2D _Property_0a40095baa8747309c5b5457affa6b23_Out_0 = UnityBuildTexture2DStructNoScale(_HologramScanlines);
            float _Split_384d7597729249498e1f8a169331c1aa_R_1 = IN.WorldSpacePosition[0];
            float _Split_384d7597729249498e1f8a169331c1aa_G_2 = IN.WorldSpacePosition[1];
            float _Split_384d7597729249498e1f8a169331c1aa_B_3 = IN.WorldSpacePosition[2];
            float _Split_384d7597729249498e1f8a169331c1aa_A_4 = 0;
            float _Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0 = _ScrollSpeed;
            float _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2;
            Unity_Multiply_float_float(_Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0, IN.TimeParameters.x, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2);
            float _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2;
            Unity_Add_float(_Split_384d7597729249498e1f8a169331c1aa_G_2, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0 = float2(0, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Property_bfe8977265394f82a18fc243a570c5e1_Out_0 = _HologramTiling;
            float2 _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3;
            Unity_TilingAndOffset_float(_Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0, _Property_bfe8977265394f82a18fc243a570c5e1_Out_0, float2 (0, 0), _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3);
            float4 _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0 = SAMPLE_TEXTURE2D(_Property_0a40095baa8747309c5b5457affa6b23_Out_0.tex, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.samplerstate, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.GetTransformedUV(_TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3));
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_R_4 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.r;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_G_5 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.g;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_B_6 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.b;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_A_7 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.a;
            float4 _Add_695108988ba248fcb0f2f77502ddb7df_Out_2;
            Unity_Add_float4(_Multiply_7b14177af4454643be3c56184b9a8791_Out_2, _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0, _Add_695108988ba248fcb0f2f77502ddb7df_Out_2);
            float _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3;
            Unity_RandomRange_float((IN.TimeParameters.x.xx), 0, 1, _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3);
            float _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2;
            Unity_Comparison_Greater_float(_RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3, 0.9, _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2);
            float _Property_d407b1bfba984e5592275c40c747bc5b_Out_0 = _FlickerIntensity;
            float _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1;
            Unity_OneMinus_float(_Property_d407b1bfba984e5592275c40c747bc5b_Out_0, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1);
            float _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3;
            Unity_Branch_float(_Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2, 1, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1, _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3);
            float4 _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2;
            Unity_Multiply_float4_float4(_Add_695108988ba248fcb0f2f77502ddb7df_Out_2, (_Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3.xxxx), _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2);
            surface.BaseColor = (_Property_34c3853187ea406bace159aae5362e16_Out_0.xyz);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Emission = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2.xyz);
            surface.Metallic = 0;
            surface.Smoothness = 0.5;
            surface.Occlusion = 1;
            surface.Alpha = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2).x;
            surface.AlphaClipThreshold = 0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
            output.WorldSpacePosition = input.positionWS;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRGBufferPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALS
        #define _ALPHATEST_ON 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 TangentSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float3 interp3 : INTERP3;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _FresnelColor;
        float _FresnelPower;
        float4 _MainColor;
        float4 _HologramScanlines_TexelSize;
        float _ScrollSpeed;
        float2 _HologramTiling;
        float _FlickerIntensity;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_HologramScanlines);
        SAMPLER(sampler_HologramScanlines);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
        {
             float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
             Out = lerp(Min, Max, randomno);
        }
        
        void Unity_Comparison_Greater_float(float A, float B, out float Out)
        {
            Out = A > B ? 1 : 0;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Branch_float(float Predicate, float True, float False, out float Out)
        {
            Out = Predicate ? True : False;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 NormalTS;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_a75280112a8848f3a168d96b9cb3d871_Out_0 = IsGammaSpace() ? LinearToSRGB(_FresnelColor) : _FresnelColor;
            float _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0 = _FresnelPower;
            float _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0, _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3);
            float4 _Multiply_7b14177af4454643be3c56184b9a8791_Out_2;
            Unity_Multiply_float4_float4(_Property_a75280112a8848f3a168d96b9cb3d871_Out_0, (_FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3.xxxx), _Multiply_7b14177af4454643be3c56184b9a8791_Out_2);
            UnityTexture2D _Property_0a40095baa8747309c5b5457affa6b23_Out_0 = UnityBuildTexture2DStructNoScale(_HologramScanlines);
            float _Split_384d7597729249498e1f8a169331c1aa_R_1 = IN.WorldSpacePosition[0];
            float _Split_384d7597729249498e1f8a169331c1aa_G_2 = IN.WorldSpacePosition[1];
            float _Split_384d7597729249498e1f8a169331c1aa_B_3 = IN.WorldSpacePosition[2];
            float _Split_384d7597729249498e1f8a169331c1aa_A_4 = 0;
            float _Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0 = _ScrollSpeed;
            float _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2;
            Unity_Multiply_float_float(_Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0, IN.TimeParameters.x, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2);
            float _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2;
            Unity_Add_float(_Split_384d7597729249498e1f8a169331c1aa_G_2, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0 = float2(0, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Property_bfe8977265394f82a18fc243a570c5e1_Out_0 = _HologramTiling;
            float2 _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3;
            Unity_TilingAndOffset_float(_Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0, _Property_bfe8977265394f82a18fc243a570c5e1_Out_0, float2 (0, 0), _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3);
            float4 _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0 = SAMPLE_TEXTURE2D(_Property_0a40095baa8747309c5b5457affa6b23_Out_0.tex, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.samplerstate, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.GetTransformedUV(_TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3));
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_R_4 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.r;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_G_5 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.g;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_B_6 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.b;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_A_7 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.a;
            float4 _Add_695108988ba248fcb0f2f77502ddb7df_Out_2;
            Unity_Add_float4(_Multiply_7b14177af4454643be3c56184b9a8791_Out_2, _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0, _Add_695108988ba248fcb0f2f77502ddb7df_Out_2);
            float _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3;
            Unity_RandomRange_float((IN.TimeParameters.x.xx), 0, 1, _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3);
            float _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2;
            Unity_Comparison_Greater_float(_RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3, 0.9, _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2);
            float _Property_d407b1bfba984e5592275c40c747bc5b_Out_0 = _FlickerIntensity;
            float _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1;
            Unity_OneMinus_float(_Property_d407b1bfba984e5592275c40c747bc5b_Out_0, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1);
            float _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3;
            Unity_Branch_float(_Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2, 1, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1, _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3);
            float4 _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2;
            Unity_Multiply_float4_float4(_Add_695108988ba248fcb0f2f77502ddb7df_Out_2, (_Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3.xxxx), _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Alpha = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2).x;
            surface.AlphaClipThreshold = 0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
            output.WorldSpacePosition = input.positionWS;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature _ EDITOR_VISUALIZATION
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD1
        #define VARYINGS_NEED_TEXCOORD2
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_META
        #define _FOG_FRAGMENT 1
        #define _ALPHATEST_ON 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 texCoord0;
             float4 texCoord1;
             float4 texCoord2;
             float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float4 interp3 : INTERP3;
             float4 interp4 : INTERP4;
             float3 interp5 : INTERP5;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.texCoord0;
            output.interp3.xyzw =  input.texCoord1;
            output.interp4.xyzw =  input.texCoord2;
            output.interp5.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.texCoord0 = input.interp2.xyzw;
            output.texCoord1 = input.interp3.xyzw;
            output.texCoord2 = input.interp4.xyzw;
            output.viewDirectionWS = input.interp5.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _FresnelColor;
        float _FresnelPower;
        float4 _MainColor;
        float4 _HologramScanlines_TexelSize;
        float _ScrollSpeed;
        float2 _HologramTiling;
        float _FlickerIntensity;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_HologramScanlines);
        SAMPLER(sampler_HologramScanlines);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
        {
             float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
             Out = lerp(Min, Max, randomno);
        }
        
        void Unity_Comparison_Greater_float(float A, float B, out float Out)
        {
            Out = A > B ? 1 : 0;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Branch_float(float Predicate, float True, float False, out float Out)
        {
            Out = Predicate ? True : False;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_34c3853187ea406bace159aae5362e16_Out_0 = IsGammaSpace() ? LinearToSRGB(_MainColor) : _MainColor;
            float4 _Property_a75280112a8848f3a168d96b9cb3d871_Out_0 = IsGammaSpace() ? LinearToSRGB(_FresnelColor) : _FresnelColor;
            float _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0 = _FresnelPower;
            float _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0, _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3);
            float4 _Multiply_7b14177af4454643be3c56184b9a8791_Out_2;
            Unity_Multiply_float4_float4(_Property_a75280112a8848f3a168d96b9cb3d871_Out_0, (_FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3.xxxx), _Multiply_7b14177af4454643be3c56184b9a8791_Out_2);
            UnityTexture2D _Property_0a40095baa8747309c5b5457affa6b23_Out_0 = UnityBuildTexture2DStructNoScale(_HologramScanlines);
            float _Split_384d7597729249498e1f8a169331c1aa_R_1 = IN.WorldSpacePosition[0];
            float _Split_384d7597729249498e1f8a169331c1aa_G_2 = IN.WorldSpacePosition[1];
            float _Split_384d7597729249498e1f8a169331c1aa_B_3 = IN.WorldSpacePosition[2];
            float _Split_384d7597729249498e1f8a169331c1aa_A_4 = 0;
            float _Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0 = _ScrollSpeed;
            float _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2;
            Unity_Multiply_float_float(_Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0, IN.TimeParameters.x, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2);
            float _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2;
            Unity_Add_float(_Split_384d7597729249498e1f8a169331c1aa_G_2, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0 = float2(0, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Property_bfe8977265394f82a18fc243a570c5e1_Out_0 = _HologramTiling;
            float2 _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3;
            Unity_TilingAndOffset_float(_Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0, _Property_bfe8977265394f82a18fc243a570c5e1_Out_0, float2 (0, 0), _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3);
            float4 _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0 = SAMPLE_TEXTURE2D(_Property_0a40095baa8747309c5b5457affa6b23_Out_0.tex, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.samplerstate, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.GetTransformedUV(_TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3));
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_R_4 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.r;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_G_5 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.g;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_B_6 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.b;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_A_7 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.a;
            float4 _Add_695108988ba248fcb0f2f77502ddb7df_Out_2;
            Unity_Add_float4(_Multiply_7b14177af4454643be3c56184b9a8791_Out_2, _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0, _Add_695108988ba248fcb0f2f77502ddb7df_Out_2);
            float _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3;
            Unity_RandomRange_float((IN.TimeParameters.x.xx), 0, 1, _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3);
            float _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2;
            Unity_Comparison_Greater_float(_RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3, 0.9, _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2);
            float _Property_d407b1bfba984e5592275c40c747bc5b_Out_0 = _FlickerIntensity;
            float _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1;
            Unity_OneMinus_float(_Property_d407b1bfba984e5592275c40c747bc5b_Out_0, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1);
            float _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3;
            Unity_Branch_float(_Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2, 1, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1, _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3);
            float4 _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2;
            Unity_Multiply_float4_float4(_Add_695108988ba248fcb0f2f77502ddb7df_Out_2, (_Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3.xxxx), _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2);
            surface.BaseColor = (_Property_34c3853187ea406bace159aae5362e16_Out_0.xyz);
            surface.Emission = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2.xyz);
            surface.Alpha = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2).x;
            surface.AlphaClipThreshold = 0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        
        
            output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
            output.WorldSpacePosition = input.positionWS;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SceneSelectionPass"
            Tags
            {
                "LightMode" = "SceneSelectionPass"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENESELECTIONPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        #define _ALPHATEST_ON 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float3 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.viewDirectionWS = input.interp2.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _FresnelColor;
        float _FresnelPower;
        float4 _MainColor;
        float4 _HologramScanlines_TexelSize;
        float _ScrollSpeed;
        float2 _HologramTiling;
        float _FlickerIntensity;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_HologramScanlines);
        SAMPLER(sampler_HologramScanlines);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
        {
             float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
             Out = lerp(Min, Max, randomno);
        }
        
        void Unity_Comparison_Greater_float(float A, float B, out float Out)
        {
            Out = A > B ? 1 : 0;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Branch_float(float Predicate, float True, float False, out float Out)
        {
            Out = Predicate ? True : False;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_a75280112a8848f3a168d96b9cb3d871_Out_0 = IsGammaSpace() ? LinearToSRGB(_FresnelColor) : _FresnelColor;
            float _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0 = _FresnelPower;
            float _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0, _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3);
            float4 _Multiply_7b14177af4454643be3c56184b9a8791_Out_2;
            Unity_Multiply_float4_float4(_Property_a75280112a8848f3a168d96b9cb3d871_Out_0, (_FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3.xxxx), _Multiply_7b14177af4454643be3c56184b9a8791_Out_2);
            UnityTexture2D _Property_0a40095baa8747309c5b5457affa6b23_Out_0 = UnityBuildTexture2DStructNoScale(_HologramScanlines);
            float _Split_384d7597729249498e1f8a169331c1aa_R_1 = IN.WorldSpacePosition[0];
            float _Split_384d7597729249498e1f8a169331c1aa_G_2 = IN.WorldSpacePosition[1];
            float _Split_384d7597729249498e1f8a169331c1aa_B_3 = IN.WorldSpacePosition[2];
            float _Split_384d7597729249498e1f8a169331c1aa_A_4 = 0;
            float _Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0 = _ScrollSpeed;
            float _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2;
            Unity_Multiply_float_float(_Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0, IN.TimeParameters.x, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2);
            float _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2;
            Unity_Add_float(_Split_384d7597729249498e1f8a169331c1aa_G_2, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0 = float2(0, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Property_bfe8977265394f82a18fc243a570c5e1_Out_0 = _HologramTiling;
            float2 _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3;
            Unity_TilingAndOffset_float(_Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0, _Property_bfe8977265394f82a18fc243a570c5e1_Out_0, float2 (0, 0), _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3);
            float4 _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0 = SAMPLE_TEXTURE2D(_Property_0a40095baa8747309c5b5457affa6b23_Out_0.tex, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.samplerstate, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.GetTransformedUV(_TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3));
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_R_4 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.r;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_G_5 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.g;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_B_6 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.b;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_A_7 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.a;
            float4 _Add_695108988ba248fcb0f2f77502ddb7df_Out_2;
            Unity_Add_float4(_Multiply_7b14177af4454643be3c56184b9a8791_Out_2, _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0, _Add_695108988ba248fcb0f2f77502ddb7df_Out_2);
            float _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3;
            Unity_RandomRange_float((IN.TimeParameters.x.xx), 0, 1, _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3);
            float _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2;
            Unity_Comparison_Greater_float(_RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3, 0.9, _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2);
            float _Property_d407b1bfba984e5592275c40c747bc5b_Out_0 = _FlickerIntensity;
            float _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1;
            Unity_OneMinus_float(_Property_d407b1bfba984e5592275c40c747bc5b_Out_0, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1);
            float _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3;
            Unity_Branch_float(_Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2, 1, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1, _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3);
            float4 _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2;
            Unity_Multiply_float4_float4(_Add_695108988ba248fcb0f2f77502ddb7df_Out_2, (_Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3.xxxx), _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2);
            surface.Alpha = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2).x;
            surface.AlphaClipThreshold = 0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        
        
            output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
            output.WorldSpacePosition = input.positionWS;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ScenePickingPass"
            Tags
            {
                "LightMode" = "Picking"
            }
        
        // Render State
        Cull Back
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENEPICKINGPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        #define _ALPHATEST_ON 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float3 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.viewDirectionWS = input.interp2.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _FresnelColor;
        float _FresnelPower;
        float4 _MainColor;
        float4 _HologramScanlines_TexelSize;
        float _ScrollSpeed;
        float2 _HologramTiling;
        float _FlickerIntensity;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_HologramScanlines);
        SAMPLER(sampler_HologramScanlines);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
        {
             float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
             Out = lerp(Min, Max, randomno);
        }
        
        void Unity_Comparison_Greater_float(float A, float B, out float Out)
        {
            Out = A > B ? 1 : 0;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Branch_float(float Predicate, float True, float False, out float Out)
        {
            Out = Predicate ? True : False;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_a75280112a8848f3a168d96b9cb3d871_Out_0 = IsGammaSpace() ? LinearToSRGB(_FresnelColor) : _FresnelColor;
            float _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0 = _FresnelPower;
            float _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0, _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3);
            float4 _Multiply_7b14177af4454643be3c56184b9a8791_Out_2;
            Unity_Multiply_float4_float4(_Property_a75280112a8848f3a168d96b9cb3d871_Out_0, (_FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3.xxxx), _Multiply_7b14177af4454643be3c56184b9a8791_Out_2);
            UnityTexture2D _Property_0a40095baa8747309c5b5457affa6b23_Out_0 = UnityBuildTexture2DStructNoScale(_HologramScanlines);
            float _Split_384d7597729249498e1f8a169331c1aa_R_1 = IN.WorldSpacePosition[0];
            float _Split_384d7597729249498e1f8a169331c1aa_G_2 = IN.WorldSpacePosition[1];
            float _Split_384d7597729249498e1f8a169331c1aa_B_3 = IN.WorldSpacePosition[2];
            float _Split_384d7597729249498e1f8a169331c1aa_A_4 = 0;
            float _Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0 = _ScrollSpeed;
            float _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2;
            Unity_Multiply_float_float(_Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0, IN.TimeParameters.x, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2);
            float _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2;
            Unity_Add_float(_Split_384d7597729249498e1f8a169331c1aa_G_2, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0 = float2(0, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Property_bfe8977265394f82a18fc243a570c5e1_Out_0 = _HologramTiling;
            float2 _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3;
            Unity_TilingAndOffset_float(_Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0, _Property_bfe8977265394f82a18fc243a570c5e1_Out_0, float2 (0, 0), _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3);
            float4 _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0 = SAMPLE_TEXTURE2D(_Property_0a40095baa8747309c5b5457affa6b23_Out_0.tex, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.samplerstate, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.GetTransformedUV(_TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3));
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_R_4 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.r;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_G_5 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.g;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_B_6 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.b;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_A_7 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.a;
            float4 _Add_695108988ba248fcb0f2f77502ddb7df_Out_2;
            Unity_Add_float4(_Multiply_7b14177af4454643be3c56184b9a8791_Out_2, _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0, _Add_695108988ba248fcb0f2f77502ddb7df_Out_2);
            float _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3;
            Unity_RandomRange_float((IN.TimeParameters.x.xx), 0, 1, _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3);
            float _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2;
            Unity_Comparison_Greater_float(_RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3, 0.9, _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2);
            float _Property_d407b1bfba984e5592275c40c747bc5b_Out_0 = _FlickerIntensity;
            float _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1;
            Unity_OneMinus_float(_Property_d407b1bfba984e5592275c40c747bc5b_Out_0, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1);
            float _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3;
            Unity_Branch_float(_Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2, 1, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1, _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3);
            float4 _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2;
            Unity_Multiply_float4_float4(_Add_695108988ba248fcb0f2f77502ddb7df_Out_2, (_Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3.xxxx), _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2);
            surface.Alpha = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2).x;
            surface.AlphaClipThreshold = 0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        
        
            output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
            output.WorldSpacePosition = input.positionWS;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            // Name: <None>
            Tags
            {
                "LightMode" = "Universal2D"
            }
        
        // Render State
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_2D
        #define _ALPHATEST_ON 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float3 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.viewDirectionWS = input.interp2.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _FresnelColor;
        float _FresnelPower;
        float4 _MainColor;
        float4 _HologramScanlines_TexelSize;
        float _ScrollSpeed;
        float2 _HologramTiling;
        float _FlickerIntensity;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_HologramScanlines);
        SAMPLER(sampler_HologramScanlines);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
        {
             float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
             Out = lerp(Min, Max, randomno);
        }
        
        void Unity_Comparison_Greater_float(float A, float B, out float Out)
        {
            Out = A > B ? 1 : 0;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Branch_float(float Predicate, float True, float False, out float Out)
        {
            Out = Predicate ? True : False;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_34c3853187ea406bace159aae5362e16_Out_0 = IsGammaSpace() ? LinearToSRGB(_MainColor) : _MainColor;
            float4 _Property_a75280112a8848f3a168d96b9cb3d871_Out_0 = IsGammaSpace() ? LinearToSRGB(_FresnelColor) : _FresnelColor;
            float _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0 = _FresnelPower;
            float _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0, _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3);
            float4 _Multiply_7b14177af4454643be3c56184b9a8791_Out_2;
            Unity_Multiply_float4_float4(_Property_a75280112a8848f3a168d96b9cb3d871_Out_0, (_FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3.xxxx), _Multiply_7b14177af4454643be3c56184b9a8791_Out_2);
            UnityTexture2D _Property_0a40095baa8747309c5b5457affa6b23_Out_0 = UnityBuildTexture2DStructNoScale(_HologramScanlines);
            float _Split_384d7597729249498e1f8a169331c1aa_R_1 = IN.WorldSpacePosition[0];
            float _Split_384d7597729249498e1f8a169331c1aa_G_2 = IN.WorldSpacePosition[1];
            float _Split_384d7597729249498e1f8a169331c1aa_B_3 = IN.WorldSpacePosition[2];
            float _Split_384d7597729249498e1f8a169331c1aa_A_4 = 0;
            float _Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0 = _ScrollSpeed;
            float _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2;
            Unity_Multiply_float_float(_Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0, IN.TimeParameters.x, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2);
            float _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2;
            Unity_Add_float(_Split_384d7597729249498e1f8a169331c1aa_G_2, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0 = float2(0, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Property_bfe8977265394f82a18fc243a570c5e1_Out_0 = _HologramTiling;
            float2 _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3;
            Unity_TilingAndOffset_float(_Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0, _Property_bfe8977265394f82a18fc243a570c5e1_Out_0, float2 (0, 0), _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3);
            float4 _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0 = SAMPLE_TEXTURE2D(_Property_0a40095baa8747309c5b5457affa6b23_Out_0.tex, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.samplerstate, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.GetTransformedUV(_TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3));
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_R_4 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.r;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_G_5 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.g;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_B_6 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.b;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_A_7 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.a;
            float4 _Add_695108988ba248fcb0f2f77502ddb7df_Out_2;
            Unity_Add_float4(_Multiply_7b14177af4454643be3c56184b9a8791_Out_2, _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0, _Add_695108988ba248fcb0f2f77502ddb7df_Out_2);
            float _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3;
            Unity_RandomRange_float((IN.TimeParameters.x.xx), 0, 1, _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3);
            float _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2;
            Unity_Comparison_Greater_float(_RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3, 0.9, _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2);
            float _Property_d407b1bfba984e5592275c40c747bc5b_Out_0 = _FlickerIntensity;
            float _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1;
            Unity_OneMinus_float(_Property_d407b1bfba984e5592275c40c747bc5b_Out_0, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1);
            float _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3;
            Unity_Branch_float(_Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2, 1, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1, _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3);
            float4 _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2;
            Unity_Multiply_float4_float4(_Add_695108988ba248fcb0f2f77502ddb7df_Out_2, (_Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3.xxxx), _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2);
            surface.BaseColor = (_Property_34c3853187ea406bace159aae5362e16_Out_0.xyz);
            surface.Alpha = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2).x;
            surface.AlphaClipThreshold = 0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        
        
            output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
            output.WorldSpacePosition = input.positionWS;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "UniversalMaterialType" = "Lit"
            "Queue"="Transparent"
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"="UniversalLitSubTarget"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
        
        // Render State
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma instancing_options renderinglayer
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DYNAMICLIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
        #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
        #pragma multi_compile_fragment _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        #pragma multi_compile _ _CLUSTERED_RENDERING
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_FORWARD
        #define _FOG_FRAGMENT 1
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define _ALPHATEST_ON 1
        #define _RECEIVE_SHADOWS_OFF 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
             float2 staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
             float2 dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
             float4 fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
             float4 shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 TangentSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float3 interp3 : INTERP3;
             float2 interp4 : INTERP4;
             float2 interp5 : INTERP5;
             float3 interp6 : INTERP6;
             float4 interp7 : INTERP7;
             float4 interp8 : INTERP8;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.staticLightmapUV;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.interp5.xy =  input.dynamicLightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp6.xyz =  input.sh;
            #endif
            output.interp7.xyzw =  input.fogFactorAndVertexLight;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.interp8.xyzw =  input.shadowCoord;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.staticLightmapUV = input.interp4.xy;
            #endif
            #if defined(DYNAMICLIGHTMAP_ON)
            output.dynamicLightmapUV = input.interp5.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp6.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp7.xyzw;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
            output.shadowCoord = input.interp8.xyzw;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _FresnelColor;
        float _FresnelPower;
        float4 _MainColor;
        float4 _HologramScanlines_TexelSize;
        float _ScrollSpeed;
        float2 _HologramTiling;
        float _FlickerIntensity;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_HologramScanlines);
        SAMPLER(sampler_HologramScanlines);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
        {
             float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
             Out = lerp(Min, Max, randomno);
        }
        
        void Unity_Comparison_Greater_float(float A, float B, out float Out)
        {
            Out = A > B ? 1 : 0;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Branch_float(float Predicate, float True, float False, out float Out)
        {
            Out = Predicate ? True : False;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_34c3853187ea406bace159aae5362e16_Out_0 = IsGammaSpace() ? LinearToSRGB(_MainColor) : _MainColor;
            float4 _Property_a75280112a8848f3a168d96b9cb3d871_Out_0 = IsGammaSpace() ? LinearToSRGB(_FresnelColor) : _FresnelColor;
            float _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0 = _FresnelPower;
            float _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0, _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3);
            float4 _Multiply_7b14177af4454643be3c56184b9a8791_Out_2;
            Unity_Multiply_float4_float4(_Property_a75280112a8848f3a168d96b9cb3d871_Out_0, (_FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3.xxxx), _Multiply_7b14177af4454643be3c56184b9a8791_Out_2);
            UnityTexture2D _Property_0a40095baa8747309c5b5457affa6b23_Out_0 = UnityBuildTexture2DStructNoScale(_HologramScanlines);
            float _Split_384d7597729249498e1f8a169331c1aa_R_1 = IN.WorldSpacePosition[0];
            float _Split_384d7597729249498e1f8a169331c1aa_G_2 = IN.WorldSpacePosition[1];
            float _Split_384d7597729249498e1f8a169331c1aa_B_3 = IN.WorldSpacePosition[2];
            float _Split_384d7597729249498e1f8a169331c1aa_A_4 = 0;
            float _Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0 = _ScrollSpeed;
            float _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2;
            Unity_Multiply_float_float(_Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0, IN.TimeParameters.x, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2);
            float _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2;
            Unity_Add_float(_Split_384d7597729249498e1f8a169331c1aa_G_2, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0 = float2(0, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Property_bfe8977265394f82a18fc243a570c5e1_Out_0 = _HologramTiling;
            float2 _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3;
            Unity_TilingAndOffset_float(_Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0, _Property_bfe8977265394f82a18fc243a570c5e1_Out_0, float2 (0, 0), _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3);
            float4 _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0 = SAMPLE_TEXTURE2D(_Property_0a40095baa8747309c5b5457affa6b23_Out_0.tex, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.samplerstate, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.GetTransformedUV(_TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3));
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_R_4 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.r;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_G_5 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.g;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_B_6 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.b;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_A_7 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.a;
            float4 _Add_695108988ba248fcb0f2f77502ddb7df_Out_2;
            Unity_Add_float4(_Multiply_7b14177af4454643be3c56184b9a8791_Out_2, _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0, _Add_695108988ba248fcb0f2f77502ddb7df_Out_2);
            float _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3;
            Unity_RandomRange_float((IN.TimeParameters.x.xx), 0, 1, _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3);
            float _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2;
            Unity_Comparison_Greater_float(_RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3, 0.9, _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2);
            float _Property_d407b1bfba984e5592275c40c747bc5b_Out_0 = _FlickerIntensity;
            float _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1;
            Unity_OneMinus_float(_Property_d407b1bfba984e5592275c40c747bc5b_Out_0, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1);
            float _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3;
            Unity_Branch_float(_Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2, 1, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1, _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3);
            float4 _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2;
            Unity_Multiply_float4_float4(_Add_695108988ba248fcb0f2f77502ddb7df_Out_2, (_Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3.xxxx), _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2);
            surface.BaseColor = (_Property_34c3853187ea406bace159aae5362e16_Out_0.xyz);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Emission = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2.xyz);
            surface.Metallic = 0;
            surface.Smoothness = 0.5;
            surface.Occlusion = 1;
            surface.Alpha = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2).x;
            surface.AlphaClipThreshold = 0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
            output.WorldSpacePosition = input.positionWS;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALS
        #define _ALPHATEST_ON 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 TangentSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float3 interp3 : INTERP3;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _FresnelColor;
        float _FresnelPower;
        float4 _MainColor;
        float4 _HologramScanlines_TexelSize;
        float _ScrollSpeed;
        float2 _HologramTiling;
        float _FlickerIntensity;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_HologramScanlines);
        SAMPLER(sampler_HologramScanlines);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
        {
             float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
             Out = lerp(Min, Max, randomno);
        }
        
        void Unity_Comparison_Greater_float(float A, float B, out float Out)
        {
            Out = A > B ? 1 : 0;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Branch_float(float Predicate, float True, float False, out float Out)
        {
            Out = Predicate ? True : False;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 NormalTS;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_a75280112a8848f3a168d96b9cb3d871_Out_0 = IsGammaSpace() ? LinearToSRGB(_FresnelColor) : _FresnelColor;
            float _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0 = _FresnelPower;
            float _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0, _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3);
            float4 _Multiply_7b14177af4454643be3c56184b9a8791_Out_2;
            Unity_Multiply_float4_float4(_Property_a75280112a8848f3a168d96b9cb3d871_Out_0, (_FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3.xxxx), _Multiply_7b14177af4454643be3c56184b9a8791_Out_2);
            UnityTexture2D _Property_0a40095baa8747309c5b5457affa6b23_Out_0 = UnityBuildTexture2DStructNoScale(_HologramScanlines);
            float _Split_384d7597729249498e1f8a169331c1aa_R_1 = IN.WorldSpacePosition[0];
            float _Split_384d7597729249498e1f8a169331c1aa_G_2 = IN.WorldSpacePosition[1];
            float _Split_384d7597729249498e1f8a169331c1aa_B_3 = IN.WorldSpacePosition[2];
            float _Split_384d7597729249498e1f8a169331c1aa_A_4 = 0;
            float _Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0 = _ScrollSpeed;
            float _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2;
            Unity_Multiply_float_float(_Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0, IN.TimeParameters.x, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2);
            float _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2;
            Unity_Add_float(_Split_384d7597729249498e1f8a169331c1aa_G_2, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0 = float2(0, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Property_bfe8977265394f82a18fc243a570c5e1_Out_0 = _HologramTiling;
            float2 _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3;
            Unity_TilingAndOffset_float(_Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0, _Property_bfe8977265394f82a18fc243a570c5e1_Out_0, float2 (0, 0), _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3);
            float4 _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0 = SAMPLE_TEXTURE2D(_Property_0a40095baa8747309c5b5457affa6b23_Out_0.tex, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.samplerstate, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.GetTransformedUV(_TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3));
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_R_4 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.r;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_G_5 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.g;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_B_6 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.b;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_A_7 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.a;
            float4 _Add_695108988ba248fcb0f2f77502ddb7df_Out_2;
            Unity_Add_float4(_Multiply_7b14177af4454643be3c56184b9a8791_Out_2, _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0, _Add_695108988ba248fcb0f2f77502ddb7df_Out_2);
            float _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3;
            Unity_RandomRange_float((IN.TimeParameters.x.xx), 0, 1, _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3);
            float _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2;
            Unity_Comparison_Greater_float(_RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3, 0.9, _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2);
            float _Property_d407b1bfba984e5592275c40c747bc5b_Out_0 = _FlickerIntensity;
            float _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1;
            Unity_OneMinus_float(_Property_d407b1bfba984e5592275c40c747bc5b_Out_0, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1);
            float _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3;
            Unity_Branch_float(_Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2, 1, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1, _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3);
            float4 _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2;
            Unity_Multiply_float4_float4(_Add_695108988ba248fcb0f2f77502ddb7df_Out_2, (_Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3.xxxx), _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Alpha = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2).x;
            surface.AlphaClipThreshold = 0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
            output.WorldSpacePosition = input.positionWS;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature _ EDITOR_VISUALIZATION
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD1
        #define VARYINGS_NEED_TEXCOORD2
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_META
        #define _FOG_FRAGMENT 1
        #define _ALPHATEST_ON 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 texCoord0;
             float4 texCoord1;
             float4 texCoord2;
             float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float4 interp3 : INTERP3;
             float4 interp4 : INTERP4;
             float3 interp5 : INTERP5;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.texCoord0;
            output.interp3.xyzw =  input.texCoord1;
            output.interp4.xyzw =  input.texCoord2;
            output.interp5.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.texCoord0 = input.interp2.xyzw;
            output.texCoord1 = input.interp3.xyzw;
            output.texCoord2 = input.interp4.xyzw;
            output.viewDirectionWS = input.interp5.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _FresnelColor;
        float _FresnelPower;
        float4 _MainColor;
        float4 _HologramScanlines_TexelSize;
        float _ScrollSpeed;
        float2 _HologramTiling;
        float _FlickerIntensity;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_HologramScanlines);
        SAMPLER(sampler_HologramScanlines);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
        {
             float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
             Out = lerp(Min, Max, randomno);
        }
        
        void Unity_Comparison_Greater_float(float A, float B, out float Out)
        {
            Out = A > B ? 1 : 0;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Branch_float(float Predicate, float True, float False, out float Out)
        {
            Out = Predicate ? True : False;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_34c3853187ea406bace159aae5362e16_Out_0 = IsGammaSpace() ? LinearToSRGB(_MainColor) : _MainColor;
            float4 _Property_a75280112a8848f3a168d96b9cb3d871_Out_0 = IsGammaSpace() ? LinearToSRGB(_FresnelColor) : _FresnelColor;
            float _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0 = _FresnelPower;
            float _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0, _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3);
            float4 _Multiply_7b14177af4454643be3c56184b9a8791_Out_2;
            Unity_Multiply_float4_float4(_Property_a75280112a8848f3a168d96b9cb3d871_Out_0, (_FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3.xxxx), _Multiply_7b14177af4454643be3c56184b9a8791_Out_2);
            UnityTexture2D _Property_0a40095baa8747309c5b5457affa6b23_Out_0 = UnityBuildTexture2DStructNoScale(_HologramScanlines);
            float _Split_384d7597729249498e1f8a169331c1aa_R_1 = IN.WorldSpacePosition[0];
            float _Split_384d7597729249498e1f8a169331c1aa_G_2 = IN.WorldSpacePosition[1];
            float _Split_384d7597729249498e1f8a169331c1aa_B_3 = IN.WorldSpacePosition[2];
            float _Split_384d7597729249498e1f8a169331c1aa_A_4 = 0;
            float _Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0 = _ScrollSpeed;
            float _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2;
            Unity_Multiply_float_float(_Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0, IN.TimeParameters.x, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2);
            float _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2;
            Unity_Add_float(_Split_384d7597729249498e1f8a169331c1aa_G_2, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0 = float2(0, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Property_bfe8977265394f82a18fc243a570c5e1_Out_0 = _HologramTiling;
            float2 _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3;
            Unity_TilingAndOffset_float(_Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0, _Property_bfe8977265394f82a18fc243a570c5e1_Out_0, float2 (0, 0), _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3);
            float4 _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0 = SAMPLE_TEXTURE2D(_Property_0a40095baa8747309c5b5457affa6b23_Out_0.tex, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.samplerstate, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.GetTransformedUV(_TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3));
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_R_4 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.r;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_G_5 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.g;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_B_6 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.b;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_A_7 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.a;
            float4 _Add_695108988ba248fcb0f2f77502ddb7df_Out_2;
            Unity_Add_float4(_Multiply_7b14177af4454643be3c56184b9a8791_Out_2, _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0, _Add_695108988ba248fcb0f2f77502ddb7df_Out_2);
            float _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3;
            Unity_RandomRange_float((IN.TimeParameters.x.xx), 0, 1, _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3);
            float _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2;
            Unity_Comparison_Greater_float(_RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3, 0.9, _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2);
            float _Property_d407b1bfba984e5592275c40c747bc5b_Out_0 = _FlickerIntensity;
            float _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1;
            Unity_OneMinus_float(_Property_d407b1bfba984e5592275c40c747bc5b_Out_0, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1);
            float _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3;
            Unity_Branch_float(_Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2, 1, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1, _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3);
            float4 _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2;
            Unity_Multiply_float4_float4(_Add_695108988ba248fcb0f2f77502ddb7df_Out_2, (_Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3.xxxx), _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2);
            surface.BaseColor = (_Property_34c3853187ea406bace159aae5362e16_Out_0.xyz);
            surface.Emission = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2.xyz);
            surface.Alpha = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2).x;
            surface.AlphaClipThreshold = 0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        
        
            output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
            output.WorldSpacePosition = input.positionWS;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SceneSelectionPass"
            Tags
            {
                "LightMode" = "SceneSelectionPass"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENESELECTIONPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        #define _ALPHATEST_ON 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float3 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.viewDirectionWS = input.interp2.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _FresnelColor;
        float _FresnelPower;
        float4 _MainColor;
        float4 _HologramScanlines_TexelSize;
        float _ScrollSpeed;
        float2 _HologramTiling;
        float _FlickerIntensity;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_HologramScanlines);
        SAMPLER(sampler_HologramScanlines);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
        {
             float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
             Out = lerp(Min, Max, randomno);
        }
        
        void Unity_Comparison_Greater_float(float A, float B, out float Out)
        {
            Out = A > B ? 1 : 0;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Branch_float(float Predicate, float True, float False, out float Out)
        {
            Out = Predicate ? True : False;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_a75280112a8848f3a168d96b9cb3d871_Out_0 = IsGammaSpace() ? LinearToSRGB(_FresnelColor) : _FresnelColor;
            float _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0 = _FresnelPower;
            float _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0, _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3);
            float4 _Multiply_7b14177af4454643be3c56184b9a8791_Out_2;
            Unity_Multiply_float4_float4(_Property_a75280112a8848f3a168d96b9cb3d871_Out_0, (_FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3.xxxx), _Multiply_7b14177af4454643be3c56184b9a8791_Out_2);
            UnityTexture2D _Property_0a40095baa8747309c5b5457affa6b23_Out_0 = UnityBuildTexture2DStructNoScale(_HologramScanlines);
            float _Split_384d7597729249498e1f8a169331c1aa_R_1 = IN.WorldSpacePosition[0];
            float _Split_384d7597729249498e1f8a169331c1aa_G_2 = IN.WorldSpacePosition[1];
            float _Split_384d7597729249498e1f8a169331c1aa_B_3 = IN.WorldSpacePosition[2];
            float _Split_384d7597729249498e1f8a169331c1aa_A_4 = 0;
            float _Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0 = _ScrollSpeed;
            float _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2;
            Unity_Multiply_float_float(_Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0, IN.TimeParameters.x, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2);
            float _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2;
            Unity_Add_float(_Split_384d7597729249498e1f8a169331c1aa_G_2, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0 = float2(0, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Property_bfe8977265394f82a18fc243a570c5e1_Out_0 = _HologramTiling;
            float2 _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3;
            Unity_TilingAndOffset_float(_Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0, _Property_bfe8977265394f82a18fc243a570c5e1_Out_0, float2 (0, 0), _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3);
            float4 _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0 = SAMPLE_TEXTURE2D(_Property_0a40095baa8747309c5b5457affa6b23_Out_0.tex, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.samplerstate, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.GetTransformedUV(_TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3));
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_R_4 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.r;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_G_5 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.g;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_B_6 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.b;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_A_7 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.a;
            float4 _Add_695108988ba248fcb0f2f77502ddb7df_Out_2;
            Unity_Add_float4(_Multiply_7b14177af4454643be3c56184b9a8791_Out_2, _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0, _Add_695108988ba248fcb0f2f77502ddb7df_Out_2);
            float _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3;
            Unity_RandomRange_float((IN.TimeParameters.x.xx), 0, 1, _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3);
            float _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2;
            Unity_Comparison_Greater_float(_RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3, 0.9, _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2);
            float _Property_d407b1bfba984e5592275c40c747bc5b_Out_0 = _FlickerIntensity;
            float _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1;
            Unity_OneMinus_float(_Property_d407b1bfba984e5592275c40c747bc5b_Out_0, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1);
            float _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3;
            Unity_Branch_float(_Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2, 1, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1, _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3);
            float4 _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2;
            Unity_Multiply_float4_float4(_Add_695108988ba248fcb0f2f77502ddb7df_Out_2, (_Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3.xxxx), _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2);
            surface.Alpha = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2).x;
            surface.AlphaClipThreshold = 0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        
        
            output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
            output.WorldSpacePosition = input.positionWS;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ScenePickingPass"
            Tags
            {
                "LightMode" = "Picking"
            }
        
        // Render State
        Cull Back
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENEPICKINGPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        #define _ALPHATEST_ON 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float3 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.viewDirectionWS = input.interp2.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _FresnelColor;
        float _FresnelPower;
        float4 _MainColor;
        float4 _HologramScanlines_TexelSize;
        float _ScrollSpeed;
        float2 _HologramTiling;
        float _FlickerIntensity;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_HologramScanlines);
        SAMPLER(sampler_HologramScanlines);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
        {
             float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
             Out = lerp(Min, Max, randomno);
        }
        
        void Unity_Comparison_Greater_float(float A, float B, out float Out)
        {
            Out = A > B ? 1 : 0;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Branch_float(float Predicate, float True, float False, out float Out)
        {
            Out = Predicate ? True : False;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_a75280112a8848f3a168d96b9cb3d871_Out_0 = IsGammaSpace() ? LinearToSRGB(_FresnelColor) : _FresnelColor;
            float _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0 = _FresnelPower;
            float _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0, _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3);
            float4 _Multiply_7b14177af4454643be3c56184b9a8791_Out_2;
            Unity_Multiply_float4_float4(_Property_a75280112a8848f3a168d96b9cb3d871_Out_0, (_FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3.xxxx), _Multiply_7b14177af4454643be3c56184b9a8791_Out_2);
            UnityTexture2D _Property_0a40095baa8747309c5b5457affa6b23_Out_0 = UnityBuildTexture2DStructNoScale(_HologramScanlines);
            float _Split_384d7597729249498e1f8a169331c1aa_R_1 = IN.WorldSpacePosition[0];
            float _Split_384d7597729249498e1f8a169331c1aa_G_2 = IN.WorldSpacePosition[1];
            float _Split_384d7597729249498e1f8a169331c1aa_B_3 = IN.WorldSpacePosition[2];
            float _Split_384d7597729249498e1f8a169331c1aa_A_4 = 0;
            float _Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0 = _ScrollSpeed;
            float _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2;
            Unity_Multiply_float_float(_Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0, IN.TimeParameters.x, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2);
            float _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2;
            Unity_Add_float(_Split_384d7597729249498e1f8a169331c1aa_G_2, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0 = float2(0, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Property_bfe8977265394f82a18fc243a570c5e1_Out_0 = _HologramTiling;
            float2 _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3;
            Unity_TilingAndOffset_float(_Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0, _Property_bfe8977265394f82a18fc243a570c5e1_Out_0, float2 (0, 0), _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3);
            float4 _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0 = SAMPLE_TEXTURE2D(_Property_0a40095baa8747309c5b5457affa6b23_Out_0.tex, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.samplerstate, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.GetTransformedUV(_TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3));
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_R_4 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.r;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_G_5 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.g;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_B_6 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.b;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_A_7 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.a;
            float4 _Add_695108988ba248fcb0f2f77502ddb7df_Out_2;
            Unity_Add_float4(_Multiply_7b14177af4454643be3c56184b9a8791_Out_2, _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0, _Add_695108988ba248fcb0f2f77502ddb7df_Out_2);
            float _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3;
            Unity_RandomRange_float((IN.TimeParameters.x.xx), 0, 1, _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3);
            float _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2;
            Unity_Comparison_Greater_float(_RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3, 0.9, _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2);
            float _Property_d407b1bfba984e5592275c40c747bc5b_Out_0 = _FlickerIntensity;
            float _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1;
            Unity_OneMinus_float(_Property_d407b1bfba984e5592275c40c747bc5b_Out_0, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1);
            float _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3;
            Unity_Branch_float(_Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2, 1, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1, _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3);
            float4 _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2;
            Unity_Multiply_float4_float4(_Add_695108988ba248fcb0f2f77502ddb7df_Out_2, (_Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3.xxxx), _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2);
            surface.Alpha = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2).x;
            surface.AlphaClipThreshold = 0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        
        
            output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
            output.WorldSpacePosition = input.positionWS;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            // Name: <None>
            Tags
            {
                "LightMode" = "Universal2D"
            }
        
        // Render State
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_2D
        #define _ALPHATEST_ON 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceNormal;
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float3 interp2 : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.viewDirectionWS = input.interp2.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _FresnelColor;
        float _FresnelPower;
        float4 _MainColor;
        float4 _HologramScanlines_TexelSize;
        float _ScrollSpeed;
        float2 _HologramTiling;
        float _FlickerIntensity;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_HologramScanlines);
        SAMPLER(sampler_HologramScanlines);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }
        
        void Unity_RandomRange_float(float2 Seed, float Min, float Max, out float Out)
        {
             float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
             Out = lerp(Min, Max, randomno);
        }
        
        void Unity_Comparison_Greater_float(float A, float B, out float Out)
        {
            Out = A > B ? 1 : 0;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Branch_float(float Predicate, float True, float False, out float Out)
        {
            Out = Predicate ? True : False;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
            float AlphaClipThreshold;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_34c3853187ea406bace159aae5362e16_Out_0 = IsGammaSpace() ? LinearToSRGB(_MainColor) : _MainColor;
            float4 _Property_a75280112a8848f3a168d96b9cb3d871_Out_0 = IsGammaSpace() ? LinearToSRGB(_FresnelColor) : _FresnelColor;
            float _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0 = _FresnelPower;
            float _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_e40d46e93a1642a1a1c93963a7621c62_Out_0, _FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3);
            float4 _Multiply_7b14177af4454643be3c56184b9a8791_Out_2;
            Unity_Multiply_float4_float4(_Property_a75280112a8848f3a168d96b9cb3d871_Out_0, (_FresnelEffect_04b9687e0b054875a3d8232be580e2f5_Out_3.xxxx), _Multiply_7b14177af4454643be3c56184b9a8791_Out_2);
            UnityTexture2D _Property_0a40095baa8747309c5b5457affa6b23_Out_0 = UnityBuildTexture2DStructNoScale(_HologramScanlines);
            float _Split_384d7597729249498e1f8a169331c1aa_R_1 = IN.WorldSpacePosition[0];
            float _Split_384d7597729249498e1f8a169331c1aa_G_2 = IN.WorldSpacePosition[1];
            float _Split_384d7597729249498e1f8a169331c1aa_B_3 = IN.WorldSpacePosition[2];
            float _Split_384d7597729249498e1f8a169331c1aa_A_4 = 0;
            float _Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0 = _ScrollSpeed;
            float _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2;
            Unity_Multiply_float_float(_Property_4c3929a302584f1dae8c6d735e0b2ad2_Out_0, IN.TimeParameters.x, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2);
            float _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2;
            Unity_Add_float(_Split_384d7597729249498e1f8a169331c1aa_G_2, _Multiply_d4efbccbf5644cf59c6476c7d4043ff1_Out_2, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0 = float2(0, _Add_2844967b8a5a491ab5a7e11391bd275f_Out_2);
            float2 _Property_bfe8977265394f82a18fc243a570c5e1_Out_0 = _HologramTiling;
            float2 _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3;
            Unity_TilingAndOffset_float(_Vector2_42f7c670e71648b08a3b93ae9e25c909_Out_0, _Property_bfe8977265394f82a18fc243a570c5e1_Out_0, float2 (0, 0), _TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3);
            float4 _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0 = SAMPLE_TEXTURE2D(_Property_0a40095baa8747309c5b5457affa6b23_Out_0.tex, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.samplerstate, _Property_0a40095baa8747309c5b5457affa6b23_Out_0.GetTransformedUV(_TilingAndOffset_818b50321a5641ab8300f5710fb9ab95_Out_3));
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_R_4 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.r;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_G_5 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.g;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_B_6 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.b;
            float _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_A_7 = _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0.a;
            float4 _Add_695108988ba248fcb0f2f77502ddb7df_Out_2;
            Unity_Add_float4(_Multiply_7b14177af4454643be3c56184b9a8791_Out_2, _SampleTexture2D_6805706dae97420c8d90b84edbff1f98_RGBA_0, _Add_695108988ba248fcb0f2f77502ddb7df_Out_2);
            float _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3;
            Unity_RandomRange_float((IN.TimeParameters.x.xx), 0, 1, _RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3);
            float _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2;
            Unity_Comparison_Greater_float(_RandomRange_cf836ccd827140bd8f4c9ed64b786398_Out_3, 0.9, _Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2);
            float _Property_d407b1bfba984e5592275c40c747bc5b_Out_0 = _FlickerIntensity;
            float _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1;
            Unity_OneMinus_float(_Property_d407b1bfba984e5592275c40c747bc5b_Out_0, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1);
            float _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3;
            Unity_Branch_float(_Comparison_14de833aaf03486785d032a0d60e7fbc_Out_2, 1, _OneMinus_48879d11fad84cd4bcaa71ae6afe8529_Out_1, _Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3);
            float4 _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2;
            Unity_Multiply_float4_float4(_Add_695108988ba248fcb0f2f77502ddb7df_Out_2, (_Branch_f2633f4362ca4c4495ba0ca6de7fd2d5_Out_3.xxxx), _Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2);
            surface.BaseColor = (_Property_34c3853187ea406bace159aae5362e16_Out_0.xyz);
            surface.Alpha = (_Multiply_c5ec13d3353c4574bb5baaa647de18cb_Out_2).x;
            surface.AlphaClipThreshold = 0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
            // must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
            float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);
        
        
            output.WorldSpaceNormal = renormFactor * input.normalWS.xyz;      // we want a unit length Normal Vector node in shader graph
        
        
            output.WorldSpaceViewDirection = normalize(input.viewDirectionWS);
            output.WorldSpacePosition = input.positionWS;
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
    }
    CustomEditorForRenderPipeline "UnityEditor.ShaderGraphLitGUI" "UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset"
    CustomEditor "UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI"
    FallBack "Hidden/Shader Graph/FallbackError"
}